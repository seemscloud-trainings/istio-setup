# Istio Umbrella Chart

This directory is one Helm application chart. Upstream Istio components are dependency subcharts; files values.<component>.yaml configure their corresponding dependency aliases. values.yaml defines only the Sidecar metadata and policy API using Opsolving common. All dependency workloads use the release namespace istio-system; gateway name overrides prevent collisions within one release.

Fresh installation is two-phase: helm install disables gateway dependencies and Sidecar while CRDs/CNI/istiod become ready, then helm upgrade --install enables all components using every values file. Subsequent upgrades use only the complete upgrade command, never bootstrap. Do not replace this with a single fresh-install command: Sidecar CRDs and gateway injection webhooks must exist first. This is an alternative fresh-install example, not an automatic migration of separately owned releases.

Use common.names.fullname, common.names.namespace, common.labels.standard and common.tplvalues helpers directly. fullnameOverride and common metadata parameters affect the parent Sidecar only. Preserve upstream dependencies and do not vendor modified helpers. Validate with existing local chart copies without fetching dependencies or deploying. Keep README snippets short and leave east-west unchanged.
