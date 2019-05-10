ARG MARKETPLACE_TOOLS_TAG
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:$MARKETPLACE_TOOLS_TAG

# Provide registry prefix and tag for default values for images.
ARG REGISTRY
ARG TAG

ADD manifest/* /data/manifest/
ADD schema.yaml /data/

ENV KUBE_LATEST_VERSION="v1.14.0"
ENV STEP_VERSION="0.10.0"

ENV STEP="/home/step"
ENV STEPPATH="/home/step"
ENV STEPDEBUG="1"
ENV CONFIGPATH="/home/step/config/ca.json"

RUN apt-get update && apt-get install -y --no-install-recommends \
  expect curl
RUN addgroup --gid 1000 step \
  && adduser --gecos "" --disabled-password -u 1000 --ingroup step step

RUN curl -L https://raw.githubusercontent.com/smallstep/certificates/v${STEP_VERSION}/autocert/install/01-step-ca.yaml -o /data/manifest/01-step-ca.yaml.template
RUN curl -L https://raw.githubusercontent.com/smallstep/certificates/v${STEP_VERSION}/autocert/install/02-autocert.yaml -o /data/manifest/02-autocert.yaml.template
RUN curl -L https://raw.githubusercontent.com/smallstep/certificates/v${STEP_VERSION}/autocert/install/03-rbac.yaml -o /data/manifest/03-rbac.yaml.template
#RUN cat /data/manifest/0*.yaml.template > /data/manifest/step.yaml.template

RUN cat /data/manifest/01-step-ca.yaml.template > /data/manifest/step.yaml.template
RUN echo "---" >> /data/manifest/step.yaml.template
RUN cat /data/manifest/02-autocert.yaml.template >> /data/manifest/step.yaml.template
#RUN echo "---" >> /data/manifest/step.yaml.template
#RUN cat /data/manifest/03-rbac.yaml.template >> /data/manifest/step.yaml.template
RUN rm -f /data/manifest/0*.yaml.template 

RUN sed -i 's/namespace: step/namespace: $NAMESPACE/g' /data/manifest/step.yaml.template
#RUN sed -i 's/name: default/name: $STEP_SERVICE_ACCOUNT/g' /data/manifest/step.yaml.template

USER step
WORKDIR /home/step

ENV CA_NAME="Autocert"
ENV CA_DNS="ca.step.svc.cluster.local,127.0.0.1"
ENV CA_ADDRESS=":4443"
ENV CA_DEFAULT_PROVISIONER="admin"
ENV CA_URL="ca.step.svc.cluster.local"

USER root
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl
RUN curl -L https://github.com/smallstep/cli/releases/download/v${STEP_VERSION}/step-cli_${STEP_VERSION}_amd64.deb -o /home/step/step-cli_${STEP_VERSION}_amd64.deb \
  && dpkg -i /home/step/step-cli_${STEP_VERSION}_amd64.deb
RUN curl -L https://github.com/smallstep/certificates/releases/download/v${STEP_VERSION}/step-certificates_${STEP_VERSION}_amd64.deb -o /home/step/step-certificates_${STEP_VERSION}_amd64.deb \
  && dpkg -i /home/step/step-certificates_${STEP_VERSION}_amd64.deb

#COPY deployer/autocert.sh /home/step/
#RUN chmod +x /home/step/autocert.sh

RUN mv -f /bin/deploy.sh /bin/deploy-original.sh
ADD deployer/entrypoint.sh /bin/deploy.sh

RUN cat /data/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /data/schema.yaml.new \
    && mv /data/schema.yaml.new /data/schema.yaml