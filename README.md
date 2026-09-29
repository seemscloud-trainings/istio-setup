## Blue - Green

### Prepare Repository

Add the Istio Helm repository and refresh its chart index.

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
```

### Install Base and CNI

Install the shared Istio CRDs and CNI node agent used by both revisions.

```bash
helm upgrade --install base istio/base \
  --namespace istio-system --create-namespace \
  --version 1.30.5 --values blue-green/values.base.yaml

helm upgrade --install cni istio/cni \
  --namespace istio-system \
  --version 1.30.5 --values blue-green/values.cni.yaml \
  --wait
```

### Install Control Planes

Install the green and blue control planes as separate Helm releases, each with its own revision and values.

```bash
helm upgrade --install istiod-green istio/istiod \
  --namespace istio-system \
  --version 1.30.5 --values blue-green/values.istiod-green.yaml \
  --wait

helm upgrade --install istiod-blue istio/istiod \
  --namespace istio-system \
  --version 1.29.8 --values blue-green/values.istiod-blue.yaml \
  --wait
```

### Install Gateways

Install a dedicated gateway for each revision using its corresponding values file.

```bash
helm upgrade --install gateway-blue istio/gateway \
  --namespace istio-gateway-system --create-namespace \
  --version 1.29.8 --values blue-green/values.gateway-blue.yaml \
  --wait

helm upgrade --install gateway-green istio/gateway \
  --namespace istio-gateway-system \
  --version 1.30.5 --values blue-green/values.gateway-green.yaml \
  --wait
```
