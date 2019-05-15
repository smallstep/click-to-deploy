#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eox pipefail

# Non-standard deployer entrypoint.
# This steps are needed to interfere with deployer - add new resource programmatically
# before dropping IAM permissions.

name="$(/bin/print_config.py \
    --xtype NAME \
    --values_mode raw)"

namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

CA_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
AUTOCERT_PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

step ca init \
  --name "$CA_NAME" \
  --dns "$CA_DNS" \
  --address "$CA_ADDRESS" \
  --provisioner "$CA_DEFAULT_PROVISIONER" \
  --with-ca-url "$CA_URL" \
  --no-db \
  --password-file <(echo "$CA_PASSWORD")

echo
echo -e "\e[1mCreating autocert provisioner...\e[0m"

expect <<EOD
spawn step ca provisioner add autocert --create
expect "Please enter a password to encrypt the provisioner private key? \\\\\\[leave empty and we'll generate one\\\\\\]: "
send "${AUTOCERT_PASSWORD}\n"
expect eof
EOD

echo
echo -e "\e[1mPreparing environment...\e[0m"

# Some `base64`s wrap lines... no thanks!
CA_BUNDLE=$(cat $(step path)/certs/root_ca.crt | base64 | tr -d '\n')

kubectl --namespace ${namespace} create configmap config --from-file $(step path)/config
kubectl --namespace ${namespace} create configmap certs --from-file $(step path)/certs
kubectl --namespace ${namespace} create configmap secrets --from-file $(step path)/secrets
kubectl --namespace ${namespace} create configmap ca-bundle --from-literal "ca-bundle=${CA_BUNDLE}"

kubectl --namespace ${namespace} create secret generic ca-password --from-literal "password=${CA_PASSWORD}"
kubectl --namespace ${namespace} create secret generic autocert-password --from-literal "password=${AUTOCERT_PASSWORD}"

FINGERPRINT=$(step certificate fingerprint $(step path)/certs/root_ca.crt)

echo
echo -e "\e[1mAutocert installed!\e[0m"
echo
echo "Store this information somewhere safe:"
echo "  CA & admin provisioner password: ${CA_PASSWORD}"
echo "  Autocert password: ${AUTOCERT_PASSWORD}"
echo "  CA Fingerprint: ${FINGERPRINT}"
echo

/bin/deploy-original.sh

NAME="$(/bin/print_config.py \
    --xtype NAME \
    --values_mode raw)"
NAMESPACE="$(/bin/print_config.py \
    --xtype NAMESPACE \
    --values_mode raw)"
export NAME
export NAMESPACE
#/bin/clean_iam_resources.sh
