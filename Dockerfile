FROM linkyard/docker-helm as helm

FROM node:carbon-alpine as node

FROM docker:stable as docker

FROM hashicorp/terraform:light as terraform

FROM infrastructureascode/aws-cli
RUN apk -v --update add \
        make \
        bash \
        && \
        rm /var/cache/apk/*
        
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=helm /bin/helm /usr/local/bin/helm
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

WORKDIR /project