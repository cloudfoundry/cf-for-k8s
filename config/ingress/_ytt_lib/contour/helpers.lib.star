load("@ytt:overlay", "overlay")

deployment = overlay.subset({"kind": "Deployment", "metadata":{"name":"envoy"}})
daemonset = overlay.subset({"kind": "DaemonSet", "metadata":{"name":"envoy"}})
match_envoy = overlay.or_op(deployment, daemonset)
