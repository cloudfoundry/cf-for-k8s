load("@ytt:data", "data")
load("overlays/add-istio-injection.lib.yaml", "add_istio_injection")
load("overlays/control-plane-network-policy.lib.yaml", "control_plane_network_policy")
load("overlays/external-routing.lib.yaml", "external_routing")
load("overlays/ingressgateway-service-nodeport.lib.yaml", "ingressgateway_service_nodeport")
load("overlays/istio-kapp-ordering.lib.yaml", "istio_kapp_ordering")
load("overlays/label-istio-ns.lib.yaml", "label_istio_ns")
load("overlays/remove-hpas-and-scale-istiod.lib.yaml", "remove_hpas_and_scale_istiod")
load("overlays/remove-resource-requirements.lib.yaml", "remove_resource_requirements")
load("overlays/use-external-dns-for-wildcard.lib.yaml", "use_external_dns_for_wildcard")
load("overlays/use-first-party-jwt-tokens.lib.yaml", "use_first_party_jwt_tokens")

all_overlays = [
  add_istio_injection,
  control_plane_network_policy,
  external_routing,
  istio_kapp_ordering,
  label_istio_ns,
  remove_hpas_and_scale_istiod,
]

if not data.values.load_balancer.enable:
  all_overlays.append(ingressgateway_service_nodeport)
end

if data.values.remove_resource_requirements:
  all_overlays.append(remove_resource_requirements)
end

if data.values.use_external_dns_for_wildcard:
  all_overlays.append(use_external_dns_for_wildcard)
end

if data.values.use_first_party_jwt_tokens:
  all_overlays.append(use_first_party_jwt_tokens)
end

