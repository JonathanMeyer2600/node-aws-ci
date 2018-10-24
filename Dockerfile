FROM linkyard/docker-helm as helm

FROM node:10-alpine as node

FROM docker:stable as docker

FROM hashicorp/terraform:light as terraform

FROM gcr.io/heptio-images/authenticator:v0.3.0-alpine-3.6 as aws-authenticator

# install kops and kubectl stable
FROM alpine:3.6 as kops
ARG KUBECTL_SOURCE=kubernetes-release/release
ARG KUBECTL_TRACK=stable.txt
ARG KUBECTL_ARCH=linux/amd64
RUN apk add --no-cache --update ca-certificates vim curl jq && \
    KOPS_URL=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq -r ".assets[] | select(.name == \"kops-linux-amd64\") | .browser_download_url") && \
    curl -SsL --retry 5 "${KOPS_URL}" > /usr/local/bin/kops && \
    chmod +x /usr/local/bin/kops && \
    KUBECTL_VERSION=$(curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_TRACK}") && \
    curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_VERSION}/bin/${KUBECTL_ARCH}/kubectl" > /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# use aws-cli:latest as base
FROM infrastructureascode/aws-cli
RUN apk -v --update add \
        make bash git openssh libressl curl \
        && \
        rm /var/cache/apk/*

COPY --from=aws-authenticator /heptio-authenticator-aws /usr/local/bin/aws-iam-authenticator
        
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=terraform /bin/terraform /usr/local/bin/terraform

COPY --from=helm /bin/helm /usr/local/bin/helm
# init helm and preinstall helm s3 plugin
RUN helm init -c && \
    helm plugin install https://github.com/hypnoglow/helm-s3.git && \
    helm plugin install https://github.com/chartmuseum/helm-push

COPY --from=kops /usr/local/bin/kops /usr/local/bin/kops
COPY --from=kops /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

WORKDIR /project