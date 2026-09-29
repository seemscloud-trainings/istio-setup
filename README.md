## Base

#### Prepare repo

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
```

#### Install

```bash
helm upgrade --install base istio/base \
  --namespace istio-system --create-namespace \
  --version 1.30.5 --values base/values.base.yaml

helm upgrade --install cni istio/cni \
  --namespace istio-system \
  --version 1.30.5 --values base/values.cni.yaml \
  --wait
```

```bash
helm upgrade --install istiod istio/istiod \
  --namespace istio-system \
  --version 1.30.5 --values base/values.istiod.yaml \
  --wait
```

```bash
helm upgrade --install gateway istio/gateway \
  --namespace istio-gateway-system --create-namespace \
  --version 1.30.5 --values base/values.gateway.yaml \
  --wait
```

##### Enable by Namespace

```bash
kubectl label namespace prod-product istio-injection=enabled --overwrite
```

## Blue - Green

#### Prepare repo

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
```

#### Install

```bash
helm upgrade --install base istio/base \
  --namespace istio-system --create-namespace \
  --version 1.30.5 --values blue-green/values.base.yaml

helm upgrade --install cni istio/cni \
  --namespace istio-system \
  --version 1.30.5 --values blue-green/values.cni.yaml \
  --wait
```

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

##### Enable by Namespace

```bash
kubectl label namespace prod-product istio.io/rev=blue --overwrite
```

```bash
kubectl label namespace prod-pricing istio.io/rev=green --overwrite
```

## Multicluster — Blue / Green

#### Prepare repo

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
```

#### Prepare Shared CA — Once

```bash
bash multicluster/generate-ca.sh
```

#### Install — Cluster A

```bash
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace istio-system topology.istio.io/network=network1 --overwrite

kubectl create secret generic cacerts --namespace istio-system \
  --from-file=.local/multicluster-ca/cluster1/ca-cert.pem \
  --from-file=.local/multicluster-ca/cluster1/ca-key.pem \
  --from-file=.local/multicluster-ca/cluster1/root-cert.pem \
  --from-file=.local/multicluster-ca/cluster1/cert-chain.pem \
  --dry-run=client -o yaml | kubectl apply -f -
```

```bash
helm upgrade --install base istio/base \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.base.yaml

helm upgrade --install cni istio/cni \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.cni.yaml --wait
```

```bash
helm upgrade --install istiod-green istio/istiod \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.istiod-green.yaml \
  --values multicluster/cluster1/values.istiod.yaml --wait

helm upgrade --install istiod-blue istio/istiod \
  --namespace istio-system --version 1.29.8 \
  --values multicluster/values.istiod-blue.yaml \
  --values multicluster/cluster1/values.istiod.yaml --wait
```

```bash
helm upgrade --install gateway-blue istio/gateway \
  --namespace istio-gateway-system --create-namespace --version 1.29.8 \
  --values multicluster/values.gateway-blue.yaml --wait

helm upgrade --install gateway-green istio/gateway \
  --namespace istio-gateway-system --create-namespace --version 1.30.5 \
  --values multicluster/values.gateway-green.yaml --wait

helm upgrade --install gateway-eastwest istio/gateway \
  --namespace istio-eastwest-system --create-namespace --version 1.30.5 \
  --values multicluster/cluster1/values.gateway-eastwest.yaml --wait

kubectl apply -f multicluster/gateway-eastwest.yaml
```

```bash
istioctl create-remote-secret --name=cluster1 --namespace istio-system \
  > .local/remote-secret-cluster1.yaml
```

##### Enable by Namespace — Cluster A

```bash
kubectl label namespace prod-pricing istio.io/rev=blue --overwrite
kubectl label namespace prod-auth istio.io/rev=blue --overwrite
kubectl label namespace prod-products istio.io/rev=green --overwrite
kubectl label namespace prod-orders istio.io/rev=green --overwrite
```

#### Install — Cluster B

```bash
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace istio-system topology.istio.io/network=network2 --overwrite

kubectl create secret generic cacerts --namespace istio-system \
  --from-file=.local/multicluster-ca/cluster2/ca-cert.pem \
  --from-file=.local/multicluster-ca/cluster2/ca-key.pem \
  --from-file=.local/multicluster-ca/cluster2/root-cert.pem \
  --from-file=.local/multicluster-ca/cluster2/cert-chain.pem \
  --dry-run=client -o yaml | kubectl apply -f -
```

```bash
helm upgrade --install base istio/base \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.base.yaml

helm upgrade --install cni istio/cni \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.cni.yaml --wait
```

```bash
helm upgrade --install istiod-green istio/istiod \
  --namespace istio-system --version 1.30.5 \
  --values multicluster/values.istiod-green.yaml \
  --values multicluster/cluster2/values.istiod.yaml --wait

helm upgrade --install istiod-blue istio/istiod \
  --namespace istio-system --version 1.29.8 \
  --values multicluster/values.istiod-blue.yaml \
  --values multicluster/cluster2/values.istiod.yaml --wait
```

```bash
helm upgrade --install gateway-blue istio/gateway \
  --namespace istio-gateway-system --create-namespace --version 1.29.8 \
  --values multicluster/values.gateway-blue.yaml --wait

helm upgrade --install gateway-green istio/gateway \
  --namespace istio-gateway-system --create-namespace --version 1.30.5 \
  --values multicluster/values.gateway-green.yaml --wait

helm upgrade --install gateway-eastwest istio/gateway \
  --namespace istio-eastwest-system --create-namespace --version 1.30.5 \
  --values multicluster/cluster2/values.gateway-eastwest.yaml --wait

kubectl apply -f multicluster/gateway-eastwest.yaml
```

```bash
istioctl create-remote-secret --name=cluster2 --namespace istio-system \
  > .local/remote-secret-cluster2.yaml
```

##### Enable by Namespace — Cluster B

```bash
kubectl label namespace prod-inventory istio.io/rev=blue --overwrite
kubectl label namespace prod-payments istio.io/rev=blue --overwrite
kubectl label namespace prod-fulfillment istio.io/rev=green --overwrite
kubectl label namespace prod-notifications istio.io/rev=green --overwrite
```

#### Enable Endpoint Discovery — Cluster A

```bash
kubectl apply -f .local/remote-secret-cluster2.yaml
```

#### Enable Endpoint Discovery — Cluster B

```bash
kubectl apply -f .local/remote-secret-cluster1.yaml
```

#### Verify — Each Cluster

```bash
istioctl remote-clusters
kubectl -n istio-eastwest-system get service gateway-eastwest
openssl x509 -in .local/multicluster-ca/cluster1/root-cert.pem -noout -fingerprint -sha256
openssl x509 -in .local/multicluster-ca/cluster2/root-cert.pem -noout -fingerprint -sha256
```
