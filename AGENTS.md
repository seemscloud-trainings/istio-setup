# Istio Setup

Training installation documentation and Helm values, not a deployed GitOps application. blue-green/ contains Karakoram-derived values for base, singleton CNI, revisioned istiod and gateways, plus optional mesh resources. README.md contains the Blue - Green heading and four snippets with English subsection headings and one short introductory sentence each: Helm repository setup, base/CNI, istiod and gateways. Omit context variables, kube-context flags and timeouts; retain --wait. Keep README concise; avoid extended explanations.

Keep blue 1.29.8 and green/shared components 1.30.5 unless explicitly updating versions. Base/CNI have one release each. Control-plane release names are istiod-blue and istiod-green. Gateway names and labels are generic, derived from the Playground participant gateway template; GKE paths/internal LoadBalancer settings and external Alloy dependency remain explicit.

Validate YAML and render with already available charts. Do not install dependencies or change clusters unless requested. This request authorizes files, commit and push only. Update README when changing filenames, commands or assumptions.
