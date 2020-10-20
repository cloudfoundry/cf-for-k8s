load("/values.star", "data")
load("overlays/label-contour-ns.lib.yaml", "label_contour_ns")
load("overlays/label-ingress-service.lib.yaml", "label_ingress_service")
load("overlays/scale-down-contour.lib.yaml", "scale_down_contour")

all_overlays = [
  label_contour_ns,
  label_ingress_service,
  scale_down_contour,
]
