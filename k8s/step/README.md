# Overview
![Autocert architecture diagram](https://raw.githubusercontent.com/smallstep/certificates/autocert/autocert/autocert-logo.png)

[![GitHub release](https://img.shields.io/github/release/smallstep/certificates.svg)](https://github.com/smallstep/certificates/releases)
[![Join the chat at https://gitter.im/smallstep/community](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/smallstep/community)
[![CA Image](https://images.microbadger.com/badges/image/smallstep/step-ca.svg)](https://microbadger.com/images/smallstep/step-ca)
[![Go Report Card](https://goreportcard.com/badge/github.com/smallstep/certificates)](https://goreportcard.com/report/github.com/smallstep/certificates)

[![GitHub stars](https://img.shields.io/github/stars/smallstep/certificates.svg?style=social)](https://github.com/smallstep/certificates/stargazers)
[![Twitter followers](https://img.shields.io/twitter/follow/smallsteplabs.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=smallsteplabs)

**Autocert** is a kubernetes add-on that automatically injects TLS/HTTPS certificates into your containers.

To get a certificate **simply annotate your pods** with a name. An X.509 (TLS/HTTPS) certificate is automatically created and mounted at `/var/run/autocert.step.sm/` along with a corresponding private key and root certificate (everything you need for [mTLS](#motivation)).

We ❤️ feedback. Please [report bugs](https://github.com/smallstep/certificates/issues/new?template=autocert_bug.md) & [suggest enhancements](https://github.com/smallstep/certificates/issues/new?template=autocert_enhancement.md). [Fork](https://github.com/smallstep/certificates/fork) and send a PR. [Give us a ⭐](https://github.com/smallstep/certificates/stargazers) if you like what we're doing.

![Autocert demo gif](https://raw.githubusercontent.com/smallstep/certificates/autocert/autocert/demo.gif)

## About Google Click to Deploy

Popular open stacks on Kubernetes packaged by Google.

### Solution Information

Simple one click installer to run step's autocert in a dedicated namespace inside a Google Kubernetes Engine cluster.

## Quick install with Google Cloud Marketplace

Please follow the steps in the Google Cloud marketplace launcher.

## Command line instructions

### Prerequisites

#### Set up command-line tools

You'll need the following tools in your development environment:
- [gcloud](https://cloud.google.com/sdk/gcloud/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [docker](https://docs.docker.com/install/)
- [pip](https://pip.pypa.io/en/stable/installing/)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

#### Create a Google Kubernetes Engine cluster

Create a new cluster from the command line.

```shell
export CLUSTER=sample-cluster
export ZONE=us-west1-a

gcloud container clusters create "$CLUSTER" --zone "$ZONE"
```

Configure `kubectl` to connect to the new cluster.

```shell
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"
```

#### Clone this repo

Clone this repo and the associated tools repo.

```shell
git clone --recursive https://github.com/GoogleCloudPlatform/click-to-deploy.git
```

#### Install the Application resource definition

An Application resource is a collection of individual Kubernetes components,
such as Services, Deployments, and so on, that you can manage as a group.

To set up your cluster to understand Application resources, run the following command:

```shell
kubectl apply -f click-to-deploy/k8s/vendor/marketplace-tools/crd/*
```

You need to run this command once.

The Application resource is defined by the
[Kubernetes SIG-apps](https://github.com/kubernetes/community/tree/master/sig-apps)
community. The source code can be found on
[github.com/kubernetes-sigs/application](https://github.com/kubernetes-sigs/application).

### Install the Application

Navigate to the `step` directory:

```shell
cd click-to-deploy/k8s/step
```

#### Configure the app with environment variables

Choose an instance name and namespace for the app. You typically use
[namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
if you have many users spread across multiple teams or projects.


```shell
export APP_INSTANCE_NAME=step-1
export NAMESPACE=step
```

Configure gcloud project (container registry to be used) and specify step version:

```shell
gcloud config set project "step-marketplace"
TAG=0.10.0
```

#### Create namespace in your Kubernetes cluster

If you use a different namespace than the `default`, run the command below to create a new namespace:

```shell
kubectl create namespace "$NAMESPACE"
```

#### Expand the manifest template

Use `envsubst` to expand the template. We recommend that you save the
expanded manifest file for future updates to the application.

```shell
awk 'BEGINFILE {print "---"}{print}' manifest/* \
  | envsubst '$APP_INSTANCE_NAME $NAMESPACE' \
  > "${APP_INSTANCE_NAME}_manifest.yaml"
```

#### Apply the manifest to your Kubernetes cluster

Use `kubectl` to apply the manifest to your Kubernetes cluster:

```shell
kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml" --namespace "${NAMESPACE}"
```

#### View the app in the Google Cloud Platform Console

To get the Console URL for your app, run the following command:

```shell
echo "https://console.cloud.google.com/kubernetes/application/${ZONE}/${CLUSTER}/${NAMESPACE}/${APP_INSTANCE_NAME}"
```

To view your app, open the URL in your browser.