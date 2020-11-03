load("@ytt:overlay", "overlay")

deployment = overlay.subset({"kind": "Deployment", "metadata":{"name":"istio-ingressgateway"}})
daemonset = overlay.subset({"kind": "DaemonSet", "metadata":{"name":"istio-ingressgateway"}})
match_ingressgateway = overlay.or_op(deployment, daemonset)
