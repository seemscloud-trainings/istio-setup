# Istio Setup

Training installation documentation and Helm values, not a deployed GitOps application. blue-green/ contains Karakoram-derived values for base, singleton CNI, revisioned istiod and gateways, plus optional mesh resources. base/ contains the single-control-plane variant at 1.30.5 with three istiod replicas and three gateway replicas, without named revisions. It uses the chart defaultRevision=default without repeating that default in values. Both variants are alternative installations, not additive releases. README.md contains the Base and Blue - Green headings and command snippets for Helm repository setup, base/CNI, istiod, gateways and namespace injection. Use exactly these subsection headings in each variant: #### Prepare repo, #### Install, ##### Enable by Namespace. Base uses istio-injection=enabled; Blue/Green uses istio.io/rev=blue or green. Remove the competing label. Keep snippets free of explanatory comments. Omit context variables, kube-context flags and timeouts; retain --wait. Keep only headings and command snippets in README; no descriptive paragraphs.

Keep blue 1.29.8 and green/shared components 1.30.5 unless explicitly updating versions. Base/CNI have one release each. Control-plane release names are istiod-blue and istiod-green. Gateway names and labels are derived from the Helm release names; GKE paths/internal LoadBalancer settings and external Alloy dependency remain explicit.

Validate YAML and render with already available charts. Do not install dependencies or change clusters unless requested. This request authorizes files, commit and push only. Update README when changing filenames, commands or assumptions.

Gateway values intentionally omit the GKE subnet annotation, explicit securityContext and inject.istio.io/templates override. Keep this simplification limited to istio-setup; infrastructure and Playground repositories retain their own configuration. Upstream chart defaults may still render these fields.

Values contain overrides only: omit entries equal to the pinned chart defaults and release-derived gateway names/labels. Base values.base.yaml is {} because all settings use chart defaults. Keep meaningful null overrides that remove default proxy/gateway limits. Verify cleanup through normalized Helm renders; only the injector ConfigMap original-values bookkeeping may differ.

CNI values omit resourceQuotas entirely in both variants, using the chart default disabled state.

Example Sidecar resources import only ./* and istio-system/*; the Alloy import is intentionally omitted. These example files are not applied to the live training cluster. Tracing through Alloy requires a separate collector visibility configuration when using this restrictive Sidecar.

Namespace label examples use only prod-product for Base, and prod-product (blue) plus prod-pricing (green) for Blue - Green.
