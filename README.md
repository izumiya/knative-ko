## GKE で skaffold

### Enable beta versions of gcloud commands
```
gcloud components update
gcloud components install beta
```

### Set variables
```
PROJECT_ID={{gcloudのプロジェクトID}}
ZONE={{gcloudのゾーン}}
CLUSTER_NAME={{作成するクラスタ名}}
```

### Set default
```
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
```

### Enable APIs
```
gcloud services enable container.googleapis.com containerregistry.googleapis.com cloudbuild.googleapis.com
```

### クラスタを作る
```
gcloud beta container clusters create $CLUSTER_NAME \
  --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
  --machine-type=n1-standard-2 \
  --cluster-version=latest \
  --zone=$ZONE \
  --enable-stackdriver-kubernetes --enable-ip-alias \
  --scopes cloud-platform \
  --preemptible
```

### カスタムドメインを設定する
```
EXTERNAL_IP=$(kubectl get service istio-ingressgateway -nistio-system -o jsonpath='{.status.loadBalancer.ingress[*].ip}')
kubectl patch configmap config-domain -nknative-serving --patch "{\"data\": {\"example.com\": null, \"$EXTERNAL_IP.xip.io\": \"\"}}"
```

### koの変数を設定する
```
export KO_DOCKER_REPO=gcr.io/$(gcloud config get-value core/project)/ko
```

### Skaffold
```
skaffold dev -f skaffold.gke.yaml
```

## Minikube で Skaffold

### minikube start
```
minikube start --memory=16384 --cpus=6 \
  --vm-driver=hyperkit \
  --disk-size=30g \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"
```
IPを割り振るためtunnelする
```
minikube tunnel
```

### gloo をインストール
```
glooctl install knative
kubectl wait --all -ngloo-system pods --for=condition=ready --timeout=300s
```

### カスタムドメインを設定する
```
EXTERNAL_IP=$(kubectl get svc -ngloo-system knative-external-proxy -o jsonpath='{.spec.clusterIP}')
kubectl patch configmap config-domain -nknative-serving --patch "{\"data\": {\"example.com\": null, \"$EXTERNAL_IP.xip.io\": \"\"}}"
```

### koの変数を設定する
```
export KO_DOCKER_REPO=ko.local
export KO_LOCAL=minikube
```

### Skaffold
```
skaffold dev -f skaffold.minikube.yaml
```

### https接続する
証明書をsecretに追加
```
mkcert -cert-file tls.crt -key-file tls.key "*.default.$EXTERNAL_IP.xip.io"
kubectl create secret tls my-knative-tls-secret \
  --key tls.key \
  --cert tls.crt \
  --namespace default
rm -f tls.crt tls.key
```
service.yaml の metadata に annotation を追加する
```
  annotations:
    gloo.networking.knative.dev/ssl.sni_domains: ko-example.default.{{ EXTERNAL_IPを入れる }}.xip.io
    gloo.networking.knative.dev/ssl.secret_name: my-knative-tls-secret
```

## References
- https://knative.dev/docs/concepts/resources/#other-resources
- https://github.com/google/ko
- https://knative.dev/blog/2018/12/18/ko-fast-kubernetes-microservice-development-in-go/
- https://blog.francium.tech/deploy-knative-service-directly-from-source-code-using-kaniko-ko-62f628a010d2
- https://github.com/GoogleContainerTools/skaffold/tree/master/examples/custom
- https://docs.solo.io/gloo/latest/knative/
