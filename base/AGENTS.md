# Istio Umbrella Chart

This directory is one Helm application chart. Upstream Istio components are dependency subcharts; files values.<component>.yaml configure their corresponding dependency aliases. values.yaml defines Sidecar and Telemetry metadata and spec APIs using Opsolving common. All dependency workloads use the release namespace istio-system; gateway name overrides prevent collisions within one release.

The owner explicitly requested one complete helm upgrade --install command with all values, without a separate bootstrap phase. Keep that README.base.md flow. Fresh-cluster CRD and injection ordering can fail; repeating the command is not guaranteed to fix missing CRDs or already-created uninjected pods. This is not automatic migration of separately owned releases.

Use common.names.fullname, common.names.namespace, common.labels.standard and common.tplvalues helpers directly. Sidecar and Telemetry names use the common helpers and release-derived defaults; values.yaml does not define fullnameOverride. Common metadata applies to both parent resources; component labels/annotations take precedence. Preserve upstream dependencies and do not vendor modified helpers. Validate with existing local chart copies without fetching dependencies or deploying. Keep README.base.md snippets short and leave east-west unchanged.
