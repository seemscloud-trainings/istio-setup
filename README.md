## Blue - Green

```bash
export CTX="<twoj-kontekst-kubernetes>"

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio

helm upgrade --install base istio/base \
  --kube-context "$CTX" --namespace istio-system --create-namespace \
  --version 1.30.5 --values blue-green/values.base.yaml

helm upgrade --install cni istio/cni \
  --kube-context "$CTX" --namespace istio-system \
  --version 1.30.5 --values blue-green/values.cni.yaml \
  --wait --timeout 10m
```

```bash
helm upgrade --install istiod-green istio/istiod \
  --kube-context "$CTX" --namespace istio-system \
  --version 1.30.5 --values blue-green/values.istiod-green.yaml \
  --wait --timeout 10m

helm upgrade --install istiod istio/istiod \
  --kube-context "$CTX" --namespace istio-system \
  --version 1.29.8 --values blue-green/values.istiod-blue.yaml \
  --wait --timeout 10m
```

```bash
helm upgrade --install gateway-blue istio/gateway \
  --kube-context "$CTX" --namespace istio-gateway-system --create-namespace \
  --version 1.29.8 --values blue-green/values.gateway-blue.yaml \
  --wait --timeout 10m

helm upgrade --install gateway-green istio/gateway \
  --kube-context "$CTX" --namespace istio-gateway-system \
  --version 1.30.5 --values blue-green/values.gateway-green.yaml \
  --wait --timeout 10m
```
