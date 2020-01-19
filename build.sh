#!/usr/bin/env bash
set -e

if [ -z "$KO_DOCKER_REPO" ]; then
    echo "envionment variable KO_DOCKER_REPO is required"
    exit 1
fi

if ! [ -x "$(command -v ko)" ]; then
    go get -mod=readonly github.com/google/ko/cmd/ko
fi

if [ -z "$KO_LOCAL" ]; then
    # gke
    ko resolve --preserve-import-paths -f service.yaml > release/k8s.yaml
else
    # minikube
    ko resolve --local --preserve-import-paths --tags= -f service.yaml > release/k8s.yaml
    ref=$(cat release/k8s.yaml | grep image: | awk '{print $2}')
    docker tag $ref $IMAGE
    if $PUSH_IMAGE; then
        docker push $IMAGE
    fi
fi
