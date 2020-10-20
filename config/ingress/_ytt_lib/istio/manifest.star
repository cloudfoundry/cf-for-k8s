load("/values.star", "data")
load("overlays/add-istio-injection.lib.yaml", "add_istio_injection")
load("overlays/external-routing.lib.yaml", "external_routing")
load("overlays/istio-kapp-ordering.lib.yaml", "istio_kapp_ordering")
load("overlays/label-istio-ns.lib.yaml", "label_istio_ns")
load("overlays/remove-hpas-and-scale-istiod.lib.yaml", "remove_hpas_and_scale_istiod")
load("overlays/remove-resource-requirements.lib.yaml", "remove_resource_requirements")
load("overlays/use-first-party-jwt-tokens.lib.yaml", "use_first_party_jwt_tokens")
load("overlays/label-ingress-service.lib.yaml", "label_ingress_service")

all_overlays = [
  add_istio_injection,
  external_routing,
  istio_kapp_ordering,
  label_istio_ns,
  remove_hpas_and_scale_istiod,
  label_ingress_service,
]

if data.values.remove_resource_requirements:
  all_overlays.append(remove_resource_requirements)
end

if data.values.use_first_party_jwt_tokens:
  all_overlays.append(use_first_party_jwt_tokens)
end

