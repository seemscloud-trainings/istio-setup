## Blue - Green

#### Prepare repo

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add opsolving https://opsolving.github.io/charts/
helm repo update istio opsolving
helm dependency update ./blue-green
```

#### Install / Upgrade

```bash
helm upgrade --install istio-blue-green ./blue-green \
  --namespace istio-system --create-namespace \
  --values blue-green/values.yaml \
  --values blue-green/values.base.yaml \
  --values blue-green/values.cni.yaml \
  --values blue-green/values.istiod-blue.yaml \
  --values blue-green/values.istiod-green.yaml \
  --values blue-green/values.gateway-blue.yaml \
  --values blue-green/values.gateway-green.yaml \
  --wait
```

##### Enable by Namespace

```bash
kubectl label namespace prod-product istio.io/rev=blue --overwrite
kubectl label namespace prod-pricing istio.io/rev=green --overwrite
```
