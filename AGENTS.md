# Istio Setup

Training installation documentation and two umbrella charts: base/ and blue-green/. Upstream Istio dependencies are declared in each Chart.yaml and configured by alias-wrapped values.<component>.yaml files. Opsolving common provides Sidecar and Telemetry helpers in templates/. Parent values.yaml owns fullnameOverride, commonLabels/commonAnnotations and Sidecar/Telemetry labels/annotations/spec. Read the chart-local AGENTS.md before editing either chart.

All base/blue-green dependency workloads, including gateways, use the release namespace istio-system. Gateway dependency names are explicit to preserve gateway, gateway-blue and gateway-green under one parent release. CNI is singleton. The standalone east-west/ examples keep their original installation layout and values; do not wrap or rewrite them during this refactor.

README keeps headings and snippets only. Dependencies are prepared explicitly by the operator. Fresh installs bootstrap base/CNI/istiod with gateways, Sidecar and Telemetry disabled, then run the full upgrade command. Subsequent upgrades only use the full command; do not disable existing gateways. No automatic adoption of the earlier standalone Helm releases is provided. Base and Blue - Green remain alternatives. Named revision selection and pinned upstream versions remain unchanged.

Validate offline with locally available dependencies. Do not fetch dependencies, run installations or mutate clusters without authorization. Existing local chart copies may be staged in ignored charts/ for rendering; do not handwrite Chart.lock. Commit and push repository changes on the current branch.

Gateway values intentionally omit the GKE subnet annotation, explicit securityContext and inject.istio.io/templates override. Keep this simplification limited to istio-setup; infrastructure and Playground repositories retain their own configuration. Upstream chart defaults may still render these fields.

Values contain overrides only: omit entries equal to the pinned chart defaults and release-derived gateway names/labels. Base values.base.yaml now contains only the dependency enabled flag. Keep meaningful null overrides that remove default proxy/gateway limits. Verify cleanup through normalized Helm renders; only the injector ConfigMap original-values bookkeeping may differ.

CNI values omit resourceQuotas entirely in both variants, using the chart default disabled state.

Example Sidecar resources import only ./* and istio-system/*; the Alloy import is intentionally omitted. These example files are not applied to the live training cluster. Tracing through Alloy requires a separate collector visibility configuration when using this restrictive Sidecar.

Namespace label examples use only prod-product for Base, and prod-product (blue) plus prod-pricing (green) for Blue - Green.

The east-west/ directory reproduces the reviewed multicluster diagram: cluster1/network1 and cluster2/network2 share mesh1; both have blue and green control planes and ingress pools, three replicas each. A green gateway-eastwest pool (three replicas) in istio-eastwest-system handles AUTO_PASSTHROUGH on 15443. The README cluster-specific snippets operate on the current context, switched manually by the operator. The two remote secrets must be generated on their respective source clusters and applied on the opposite cluster.

Shared trust is created once using generate-ca.sh, with one root and separate intermediate CAs. The helper refuses an existing output directory and is not executed during repository work. Local keys and remote secrets are ignored under .local/. Install cacerts before either istiod in a fresh cluster; these examples do not rotate an existing mesh CA. API servers must be reachable from peer istiod pods; east-west LoadBalancer IPs must be reachable from peer proxies. Public east-west LoadBalancers are chart defaults; north-south gateways retain the existing GKE internal setting. Cloud L7 ALBs, firewall/VPC connectivity and application routes are external prerequisites, not provisioned by these charts. Application namespaces must exist before labeling.

Do not apply the restrictive Base/Blue-Green Sidecar examples as a multicluster default: remote service imports and collector visibility must be considered separately. Services addressed through Kubernetes DNS need a local Service definition (or separately configured Istio DNS capture) on the source cluster; remote endpoints alone do not create Kubernetes DNS records. The installation sets up reciprocal discovery/transport; actual cross-cluster request verification requires application Services, trust and network reachability.
