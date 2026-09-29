## Base

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

## Multicluster — Blue / Green

#### Preparations

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add opsolving https://opsolving.github.io/charts/
helm repo update istio opsolving
helm dependency update ./east-west
bash east-west/scripts/generate-ca.sh
```

#### Preparations — Cluster A

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

#### Install / Upgrade — Cluster A

```bash
helm upgrade --install istio-east-west ./east-west \
  --namespace istio-system --create-namespace \
  --values east-west/values.yaml \
  --values east-west/values.base.yaml \
  --values east-west/values.cni.yaml \
  --values east-west/values.istiod-blue.yaml \
  --values east-west/values.istiod-green.yaml \
  --values east-west/values.gateway-blue.yaml \
  --values east-west/values.gateway-green.yaml \
  --values east-west/cluster1/values.istiod.yaml \
  --values east-west/cluster1/values.gateway-eastwest.yaml \
  --wait
```

```bash
istioctl create-remote-secret --name=cluster1 --namespace istio-system \
  > .local/remote-secret-cluster1.yaml
```

#### Preparations — Cluster B

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

#### Install / Upgrade — Cluster B

```bash
helm upgrade --install istio-east-west ./east-west \
  --namespace istio-system --create-namespace \
  --values east-west/values.yaml \
  --values east-west/values.base.yaml \
  --values east-west/values.cni.yaml \
  --values east-west/values.istiod-blue.yaml \
  --values east-west/values.istiod-green.yaml \
  --values east-west/values.gateway-blue.yaml \
  --values east-west/values.gateway-green.yaml \
  --values east-west/cluster2/values.istiod.yaml \
  --values east-west/cluster2/values.gateway-eastwest.yaml \
  --wait
```

```bash
istioctl create-remote-secret --name=cluster2 --namespace istio-system \
  > .local/remote-secret-cluster2.yaml
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
kubectl -n istio-system get service gateway-eastwest
openssl x509 -in .local/multicluster-ca/cluster1/root-cert.pem -noout -fingerprint -sha256
openssl x509 -in .local/multicluster-ca/cluster2/root-cert.pem -noout -fingerprint -sha256
```

##### Enable by Namespace — Cluster A

```bash
kubectl label namespace prod-pricing istio.io/rev=blue --overwrite
kubectl label namespace prod-auth istio.io/rev=blue --overwrite
kubectl label namespace prod-products istio.io/rev=green --overwrite
kubectl label namespace prod-orders istio.io/rev=green --overwrite
```

##### Enable by Namespace — Cluster B

```bash
kubectl label namespace prod-inventory istio.io/rev=blue --overwrite
kubectl label namespace prod-payments istio.io/rev=blue --overwrite
kubectl label namespace prod-fulfillment istio.io/rev=green --overwrite
kubectl label namespace prod-notifications istio.io/rev=green --overwrite
```
