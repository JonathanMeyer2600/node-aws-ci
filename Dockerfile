FROM linkyard/docker-helm as helm

FROM infrastructureascode/aws-cli as aws-cli

FROM docker:stable as docker

FROM node:8.12-alpine
RUN apk -v --update add \
        make \
        bash \
        && \
        rm /var/cache/apk/*
        
COPY --from=aws-cli / /
COPY --from=helm /bin/helm /bin/helm
COPY --from=docker /usr/local/bin/docker /bin/

WORKDIR /project