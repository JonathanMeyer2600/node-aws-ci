#!/bin/sh

docker build -t node-aws-ci .
docker tag node-aws-ci jonmeyer/node-aws-ci:latest
docker push jonmeyer/node-aws-ci