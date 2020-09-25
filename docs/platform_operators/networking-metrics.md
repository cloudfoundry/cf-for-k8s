# Networking Metrics

The networking plane emits several useful metrics that can be used to understand
the health of the platform. These metrics can be consumed by Prometheus and
graphed with Grafana, but the installation and configuration of those tools are
outside of the scope of this document.

## Istio Emitted Metrics

More information on Istio metrics can be found
[here](https://istio.io/latest/docs/reference/config/policy-and-telemetry/metrics/).

Here are the most relevant:

* `istio_requests_total` (integer) -- Total number of requests
* `istio_request_duration` (histogram) -- Duration of requests
* `istio_request_bytes` (histogram) -- Size of requests
* `istio_response_bytes` (histogram) -- Size of responses

## Envoy Emitted Metrics

Note that these metrics are emitted for both the ingress gateways, and the
sidecars, so they will need to be filtered.

The full list of metrics envoy supports are listed
[here](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats),
however Envoy as configured by Istio does not emit all of those listed.

Here are a few we find valuable:

* `envoy_cluster_upstream_rq_<status word>` (integer) -- Number of requests in that
  status (i.e. `cancelled`, `completed`, `total`)
* `envoy_cluster_upstream_rq_<http status code>` (integer) -- Number of requests
  that had that status code (i.e. `200`, `404`, `503`)

## General resource metrics that may be valuable

As you might expect, data and control plane components emit the standard set of
resource usage metrics, including the following

* `container_cpu_usage_seconds` (integer)
* `container_memory_usage_bytes` (integer)

## Sample Prometheus Queries

P95 Request duration:
```
histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (le))
```

Global requests per second:
```
round(sum(irate(istio_requests_total{reporter="destination"}[1m])), 0.001)
```

CPU Usage per 1k requests per second for ingressgateways
```
(sum(irate(container_cpu_usage_seconds_total{pod=~"istio-ingressgateway-.*",container="istio-proxy"}[1m])) / (round(sum(irate(istio_requests_total{source_workload="istio-ingressgateway", reporter="source"}[1m])), 0.001)/1000))
```

Additional helpful queries can be lifted from the [Istio preconfigured grafana
dashboards](https://istio.io/latest/docs/ops/integrations/grafana/).

