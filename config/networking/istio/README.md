## Istio configuration

This folder contains overlays and configuration to set up Istio in CF for K8s.

Currently, CF for K8s is tightly coupled to Istio and to this configuration in particular.

However, we strongly encourage CF users to treat this configuration as an implementation detail, and to not depend on it.
Over time, as we work to support a wider variety of networking technologies within CF for K8s, this configuration may change,
and the Istio integration may become optional, rather than required.
