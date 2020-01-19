#!/bin/bash

minikube start --memory=16384 --cpus=6 \
  --vm-driver=hyperkit \
  --disk-size=30g \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

glooctl install knative
kubectl wait --all -ngloo-system pods --for=condition=ready --timeout=300s

EXTERNAL_IP=$(kubectl get svc -ngloo-system knative-external-proxy -o jsonpath='{.spec.clusterIP}')
kubectl patch configmap config-domain -nknative-serving --patch "{\"data\": {\"example.com\": null, \"$EXTERNAL_IP.nip.io\": \"\"}}"

kubectl cluster-info