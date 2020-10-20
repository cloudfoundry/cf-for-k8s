# Networking Metrics and Monitoring

The networking control plane emits metrics that can be used to understand the
health of the platform. These metrics can be consumed by Prometheus and graphed
with Grafana, but the installation and configuration of those tools is outside
the scope of this document.

## Official Resources

There is existing official documentation on what metrics each component exposes.

* [Istio metrics](https://istio.io/latest/docs/reference/config/policy-and-telemetry/metrics/)
* [Istio preconfigured grafana dashboards](https://istio.io/latest/docs/ops/integrations/grafana/)
  * These dashboards have helpful Prometheus queries and demonstrate what the
    Istio community finds valuable to monitor when running Istio.
* [Full list of Envoy metrics](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
  * However, Envoy as configured by Istio does not emit all of the ones listed.
* [More Envoy metrics docs](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/statistics#server%5C)

# Is the platform healthy?

One goal you might have when monitoring is to ensure that requests are being
served and that the components are not becoming overloaded.

## Dataplane Monitoring

Significant changes in the number or size of requests is a sign that load on the
cluster is changing and the ingress-gateways might need to be scaled. Because
Istio configures Envoy to output data plane metrics, it is possible to measure
the global dataplane load across all Envoys.

1. The following query will return the rate of requests per second across all
   Envoy proxies configured by Istio:
   ```
   round(sum(irate(istio_requests_total{reporter="destination"}[1m])), 0.001)
   ```
1. The following query will return the 95th percentile of request latency in
   milliseconds across all Envoy proxies configured by Istio:
   ```
   histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (le))
   ```
1. The following query will return the 95th percentile of HTTP request body size
   across all Envoy proxies configured by Istio:
   ```
   histogram_quantile(0.95, sum(rate(istio_request_bytes_bucket[5m])) by (le))
   ```
1. The following query will return the 95th percentile of HTTP response body size
   across all Envoy proxies configured by Istio:
   ```
   histogram_quantile(0.95, sum(rate(istio_response_bytes_bucket[5m])) by (le))
   ```

In addition to measuring the load, it can be useful to watch out for spikes in
the rate of error codes or cancelled requests:

1. The following query will return the current rate of requests per second that have a
   particular status (e.g. `cancelled`, `completed`, `total`):
   ```
   round(sum(irate(envoy_cluster_upstream_rq_<status word>[1m])), 0.001)
   ```
1. The following query will return the current rate of requests per second that have a
   particular status code (e.g. `200`, `404`, `503`):
   ```
   round(sum(irate(envoy_cluster_upstream_rq_<http status code>[1m])), 0.001)
   ```

Note that these metrics are emitted for both the ingress-gateways, and the
sidecars, so if you want to monitor the sidecars and the ingress-gateways
separately, then the metrics will need to be filtered.
For example, the following query will return the rate of `503`s per second across
all the ingress-gateways:
```
sum(irate(envoy_cluster_upstream_rq_503{namespace="istio-system"}[1m]))
```

## Gateway Health Metrics
Monitoring the self-reported state of the ingress-gateways is one way to
determine the health of the ingress-gateways. The relevant metrics for that
monitoring are:

1. The following query will return the time since each ingress-gateway last
   restarted:
   ```
   envoy_server_uptime{pod_name=~"istio-ingressgateway-.*"}
   ```

1. The following query will return the current state of each ingress-gateway:
   ```
   envoy_server_state{pod_name=~"istio-ingressgateway-.*"}
   ```
   * This `envoy_server_state` has the following values:
     * 0: live
     * 1: draining
     * 2: pre-initializing
     * 3: initializing
   * When no upgrade is running and no scaling has be initiated, the
     ingress-gateways should be in state `0: live`. During an upgrade, some pods
     would be spinning up (in states `2: pre-initializing` and `3:
     initializing`) and others would be `1: draining` to make room for the new
     pods.

1. The following query will return the current number of live ingress-gateways:
   ```
   sum(envoy_server_live{pod_name=~"istio-ingressgateway-.*"})
   ```
## General Resource Metrics
For all the components, you can monitor the standard set of resource usage
metrics, such as the following queries that measure efficiency:

1. The following query will return the ingress-gateway CPU usage per thousand requests per second:
   ```
   sum(irate(container_cpu_usage_seconds_total{pod=~"istio-ingressgateway-.*",container="istio-proxy"}[1m]))
   / (round(
        sum(irate(
          istio_requests_total{source_workload="istio-ingressgateway", reporter="source"}[1m])),
        0.001)
      / 1000)
   ```
1. The following query will return the ingress-gateway memory usage per thousand requests per second:
   ```
   sum(irate(container_memory_usage_bytes{pod=~"istio-ingressgateway-.*",container="istio-proxy"}[1m]))
   / (round(
        sum(irate(
          istio_requests_total{source_workload="istio-ingressgateway", reporter="source"}[1m])),
        0.001)
      / 1000)
   ```

# Control Plane Latency

The path from making a configuration change using the CF CLI to that change
being applied in Envoy (especially the Envoy ingress-gateways) has a series of
steps. It is recommended to monitor each step separately in order to ensure that
control plane latency is not too high overall and to make fixing latency
problems easier. This section will cover metrics relevant to monitoring each
step.

Because most steps involve the K8s API, we will first cover the K8s API metrics that are
relevant to all those steps.

## K8s API Metrics

All of the metrics beginning with `apiserver_request_`  measure the load on the
K8s API server.

1. The following query measures the current latency on the various API server
   actions (e.g. CREATE, WATCH) and resources (e.g. pods):
   ```
   apiserver_request_duration_seconds_bucket
   ```

1. The following query will return the number of requests per second
   to the API server over the range of a minute, rounded to the nearest
   thousandth:
   ```
   round(sum(irate(apiserver_request_total[1m])), 0.001)
   ```

1. The following query will return errors from the API server such as HTTP 5xx
   errors:
   ```
   rate(apiserver_request_count{code=~"^(?:5..)$"}[5m]) / rate(apiserver_request_count[5m])
   ```
   * `(?:5..)` can be replaced with other status codes numbers (e.g. `(?:4..)`
     for HTTP 4xx errors).

1. The following query will return the 95th percentile latency for all
   Kubernetes resources and verbs:
   ```
   histogram_quantile(0.95,
   sum(rate(apiserver_request_duration_seconds_bucket[5m])) by (le, resource,
   subresource, verb))
   ```
   * It is also possible to select specific resources such as virtual services
     by adding the resource name to the metric.  For example, the query below
     will return the 95th precentile request duration latency for
     VirtualServices only.
     ```
     histogram_quantile(0.95,
     sum(rate(apiserver_request_duration_seconds_bucket{resource="virtualservices"}[5m]))
     by (le, resource, subresource, verb))
     ```

## CC API
The CC API creates or updates a Route CR to reflect changes requested by a CF
CLI command. The CC API does not emit metrics, so K8s API metrics related to
Route CRs are the most relevant.

## Route Controller
The Route Controller consumes Route CRs and outputs Istio configuration as other
CRs. There are no metrics output by Route Controller at this time, so the most
relevant metrics are emitted by the K8s API.

## Istio Metrics
Istio consumes its config as VirtualService CRs and emits configuration to each
Envoy via XDS. In addition to K8s API metrics related to VirtualServices, istiod
outputs several relevant metrics:

1. The following query will return the 99th percentile latency of Istio sending
   configuration to Envoy (measured from when Istio is ready to send a new
   configuration to when Envoy acknowledges the configuration):
   ```
   histogram_quantile(0.99, sum(rate(pilot_proxy_convergence_time_bucket[1m])) by (le))
   ```
