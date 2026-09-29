#### Prepare repo

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add opsolving https://opsolving.github.io/charts/
helm repo update istio opsolving
helm dependency update ./base
```

#### Install / Upgrade

```bash
helm upgrade --install istio-base ./base \
  --namespace istio-system --create-namespace \
  --values base/values.yaml \
  --values base/values.base.yaml \
  --values base/values.cni.yaml \
  --values base/values.istiod.yaml \
  --values base/values.gateway.yaml \
  --wait
```

##### Enable by Namespace

```bash
kubectl label namespace prod-product istio-injection=enabled --overwrite
```
