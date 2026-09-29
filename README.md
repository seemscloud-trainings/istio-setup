# Istio Setup — Blue / Green

Instalacja Istio z sidecarami przez Helm na podstawie konfiguracji Karakoram. Dwa control plane i dwa gatewaye działają równolegle; base/CRD i Istio CNI są wspólne. Polecenia wykonuj z katalogu głównego repo.

## Komponenty

| Komponent | Release Helm | Chart / wersja | Namespace | Values |
|---|---|---|---|---|
| Base / CRD | base | istio/base 1.30.5 | istio-system | [values.base.yaml](blue-green/values.base.yaml) |
| CNI DaemonSet | cni | istio/cni 1.30.5 | istio-system | [values.cni.yaml](blue-green/values.cni.yaml) |
| Istiod blue | istiod | istio/istiod 1.29.8 | istio-system | [values.istiod-blue.yaml](blue-green/values.istiod-blue.yaml) |
| Istiod green | istiod-green | istio/istiod 1.30.5 | istio-system | [values.istiod-green.yaml](blue-green/values.istiod-green.yaml) |
| Gateway blue | gateway-blue | istio/gateway 1.29.8 | istio-gateway-system | [values.gateway-blue.yaml](blue-green/values.gateway-blue.yaml) |
| Gateway green | gateway-green | istio/gateway 1.30.5 | istio-gateway-system | [values.gateway-green.yaml](blue-green/values.gateway-green.yaml) |

Release `istiod` odpowiada nazwie w Argo. Jego `revision: blue` tworzy Deployment/Service `istiod-blue`. CNI pozostaje jednym DaemonSetem dla obu rewizji, także gdy jego values zawiera `revision: green`.

**Aktualne Argo instaluje CNI w `istio-system`, nie `kube-system`.** Nie instaluj drugiej kopii w innym namespace.

## Pochodzenie i dostosowanie

- Base, CNI i istiod pochodzą z `presemantic/deploy`, `prod-common-apps/karakoram/system/istio/`. Wersje i nazwy releases pochodzą z overlay Andes w `presemantic/argo-self`.
- Z values usunięto `ignoreDifferences`: to mechanizm Argo Application, nie Helm. Pozostałe wartości tych czterech plików zachowano.
- Gatewaye bazują na generatorze Playground (`playground-app-core-api/internal/forgejo/client.go`). Zachowano porty, jedną replikę, zasoby, RBAC, injection i GKE Internal LoadBalancer. Nazwy i selector `istio` to tutaj `gateway-blue` / `gateway-green`, bez aliasu uczestnika.
- `cniBinDir: /home/kubernetes/bin` oraz subnet `gke-zeus-lb` są specyficzne dla GKE/Karakoram. W innym środowisku dostosuj je do providera. Gatewaye są wewnętrzne: klient musi mieć dostęp do ich adresów IP.
- Istiod ma jedną replikę na rewizję (`autoscaleMin/Max: 1`), każdy gateway również jedną. Diagramy z trzema podami pokazują wariant HA, nie liczbę replik tych values.
- Tracing wskazuje istniejący collector `alloy.alloy-system.svc.cluster.local:4317`. Repo nie instaluje Alloy, Tempo, Prometheusa, DNS, cert-manager ani aplikacji.

Instrukcja służy instalacji w wybranym klastrze. Istniejący Karakoram jest zarządzany przez Argo — nie przejmuj jego zasobów ręcznym Helmem. Argo renderuje chart z releaseName, ale nie tworzy standardowego release Helm.

## 1. Kontekst i repozytorium Helm

```bash
export CTX="<twoj-kontekst-kubernetes>"
kubectl --context "$CTX" cluster-info

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update istio
```

W każdym poleceniu wskazujemy kontekst jawnie. Wersje są przypięte do konfiguracji szkoleniowej.

## 2. Wspólne base i CNI

```bash
helm upgrade --install base istio/base \
  --kube-context "$CTX" --namespace istio-system --create-namespace \
  --version 1.30.5 --values blue-green/values.base.yaml

helm upgrade --install cni istio/cni \
  --kube-context "$CTX" --namespace istio-system \
  --version 1.30.5 --values blue-green/values.cni.yaml \
  --wait --timeout 10m
```

Base wskazuje `defaultRevision: green` dla domyślnego validatora. Nie przełącza to automatycznie namespace aplikacji. Dlatego green instalujemy jako pierwszy control plane.

## 3. Istiod green i blue

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

Obie rewizje korzystają z lokalnego Kubernetes API i konfigurują swoje proxy przez xDS. Base i CNI aktualizuje się jako wspólne komponenty, a nie przez instalację ich dwóch wersji.

## 4. Gatewaye blue i green

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

Namespace gatewayów nie powinien mieć `istio-injection=disabled`. Każdy Deployment wybiera własną rewizję przez values; nie ustawiaj jednej wspólnej rewizji dla namespace obu gatewayów.

Helm tworzy workloady Envoy oraz Service LoadBalancer. Osobno definiujesz zasoby Istio Gateway i VirtualService. Przykładowy Gateway HTTP dla blue:

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: app-blue
  namespace: istio-gateway-system
spec:
  selector:
    istio: gateway-blue
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - app.example.com
```

Dla green użyj innej nazwy Gateway i selectora `istio: gateway-green`. VirtualService musi wskazywać właściwy Gateway, host i Service aplikacji. DNS kieruje na wybrany LoadBalancer lub osobny L7 load balancer przed nimi. Sama instalacja chartu gateway nie tworzy tras HTTP.

HTTPS wymaga listenera 443 z `tls.mode: SIMPLE` i `credentialName`. Secret TLS umieść w namespace workloadu gatewaya (`istio-gateway-system`), także gdy Gateway jest zdefiniowany przy aplikacji. Repo nie zawiera certyfikatów ani kluczy.

## 5. Rewizja aplikacji i przełączenie blue → green

Nowy namespace:

```bash
kubectl --context "$CTX" create namespace demo
kubectl --context "$CTX" label namespace demo istio.io/rev=blue --overwrite
```

Jeśli istniejący namespace ma etykietę `istio-injection`, usuń ją przed użyciem rewizji:

```bash
kubectl --context "$CTX" label namespace demo istio-injection-
```

Następnie wdrażaj swoje Deploymenty. CNI przygotowuje przekierowanie ruchu do sidecara bez uprzywilejowanego `istio-init` konfigurującego sieć.

Migracja wskazanej istniejącej aplikacji na green:

```bash
kubectl --context "$CTX" label namespace demo istio.io/rev=green --overwrite
kubectl --context "$CTX" -n demo rollout restart deployment/<nazwa-aplikacji>
kubectl --context "$CTX" -n demo rollout status deployment/<nazwa-aplikacji> --timeout=5m
```

Sama etykieta nie wymienia proxy w działających Podach. Rewizja aplikacji i wybór ingress gatewaya są niezależne. Rollback: wróć do `istio.io/rev=blue` i wykonaj rollout tej samej aplikacji.

## 6. Opcjonalne tracing i Sidecar

Jeśli Alloy i Tempo są już skonfigurowane, zastosuj szkoleniową Telemetry z samplingiem 100%:

```bash
kubectl --context "$CTX" apply -f blue-green/config/telemetry.yaml
```

Jeżeli istnieje już mesh-wide Telemetry, scal konfigurację zamiast tworzyć konkurencyjny zasób.

[Sidecar/default](blue-green/config/sidecar.yaml) odwzorowuje ograniczenie widoczności usług Karakoram:

```yaml
egress:
  - hosts:
      - "./*"
      - "istio-system/*"
      - "alloy-system/alloy.alloy-system.svc.cluster.local"
```

Opcjonalne zastosowanie:

```bash
kubectl --context "$CTX" apply -f blue-green/config/sidecar.yaml
```

Obejmuje własny namespace, istio-system i collector Alloy. Inne zależności między namespace wymagają rozszerzenia hosts lub lokalnego Sidecar. To zakres konfiguracji proxy, nie polityka autoryzacji. Import Alloy jest potrzebny, żeby eksporter OTLP miał skonfigurowany cel w Envoy.

Zmiany Sidecar/Telemetry docierają przez xDS bez restartu podów. Sprawdzaj tracing na nowych requestach HTTP — brakujące stare ślady nie pojawią się wstecz.

## 7. Weryfikacja

```bash
helm list --kube-context "$CTX" --namespace istio-system
helm list --kube-context "$CTX" --namespace istio-gateway-system
kubectl --context "$CTX" -n istio-system get deployments,daemonsets,pods
kubectl --context "$CTX" -n istio-gateway-system get deployments,pods,services
kubectl --context "$CTX" get namespaces -L istio.io/rev,istio-injection
istioctl --context "$CTX" proxy-status
```

Sprawdź CNI na węzłach, oba istiod, gatewaye i faktyczne obrazy proxy aplikacji. Ready nie dowodzi wyboru właściwej rewizji. Zweryfikuj również trasę HTTP oraz TLS po ich osobnym skonfigurowaniu.

## Dokumentacja upstream

- [Instalacja Helm](https://istio.io/latest/docs/setup/install/helm/)
- [Upgrade Helm z rewizjami](https://istio.io/latest/docs/setup/upgrade/helm/)
- [Istio CNI](https://istio.io/latest/docs/setup/additional-setup/cni/)
