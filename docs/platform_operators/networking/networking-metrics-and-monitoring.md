# Networking Metrics and Monitoring

The networking control plane emits metrics that can be used to understand the
health of the platform. These metrics can be consumed by Prometheus and graphed
with Grafana, but the installation and configuration of those tools is outside
the scope of this document.

## Official Resources

There is existing official documentation on what metrics each component exposes.

* [Contour metrics](https://projectcontour.io/guides/prometheus/)
* [Contour preconfigured Grafana
  dashboard](https://projectcontour.io/guides/prometheus/#deploy-grafana)
  * These dashboards have helpful Prometheus queries and demonstrate what the
    Contour community finds valuable to monitor when running Contour.
* [List of Envoy cluster manager metrics (upstream/apps metrics)](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
  * However, Envoy as configured by Contour does not emit all of the ones listed.
* [List of Envoy connection manager metrics docs (downstream/client metrics)](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/stats)
* [More Envoy metrics docs](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/statistics#server%5C)

# Is the platform healthy?

One goal you might have when monitoring is to ensure that requests are being
served and that the components are not becoming overloaded.

## Dataplane Monitoring

Significant changes in the number or size of requests is a sign that load on the
cluster is changing and the Envoys might need to be scaled. Because
Contour configures Envoy to output data plane metrics, it is possible to measure
the global dataplane load across all Envoys.

1. The following query will return the rate of requests per second across all
   Envoy proxies configured by Contour:
   ```
   round(sum(irate(envoy_http_downstream_rq_total{namespace="projectcontour"}[1m])), 0.001)
   ```
1. The following query will return the 95th percentile of request latency in
   milliseconds across all Envoy proxies configured by Contour:
   ```
   histogram_quantile(0.95, sum(rate(envoy_http_downstream_rq_time_bucket{namespace="projectcontour"}[1m])) by (le))
   ```

In addition to measuring the load, it can be useful to watch out for spikes in
the rate of error codes or cancelled requests:

1. The following query will return the current rate of requests per second that have a
   particular status (e.g. `cancelled`, `completed`, `total`):
   ```
   round(sum(irate(envoy_cluster_upstream_rq_<status_word>{namespace="projectcontour"}[1m])), 0.001)
   ```
1. The following query will return the current rate of requests per second that have a
   particular status code (e.g. `200`, `404`, `503`):
   ```
   round(sum(irate(envoy_cluster_upstream_rq_<http status code>{namespace="projectcontour"}[1m])), 0.001)
   ```

## Gateway Health Metrics
Monitoring the self-reported state of the Envoys is on way to
determine the health of the Envoys. The relevant metrics for that
monitoring are:

1. The following query will return the time since each Envoy last
   restarted:
   ```
   envoy_server_uptime{namespace="projectcontour"}
   ```

1. The following query will return the current state of each Envoy:
   ```
   envoy_server_state{namespace="projectcontour"}
   ```
   * This `envoy_server_state` has the following values:
     * 0: live
     * 1: draining
     * 2: pre-initializing
     * 3: initializing
   * When no upgrade is running and no scaling has be initiated, the
     Envoys should be in state `0: live`. During an upgrade, some pods
     would be spinning up (in states `2: pre-initializing` and `3:
     initializing`) and others would be `1: draining` to make room for the new
     pods.

1. The following query will return the current number of live Envoys:
   ```
   sum(envoy_server_live{namespace="projectcontour"})
   ```
## General Resource Metrics
For all the components, you can monitor the standard set of resource usage
metrics, such as the following queries that measure efficiency:

1. The following query will return the Envoy CPU usage per thousand requests per second:
   ```
   sum(irate(container_cpu_usage_seconds_total{container="envoy",pod=~"envoy-.*"}[1m]))
   / (round(
        sum(irate(
          envoy_http_downstream_rq_total{namespace="projectcontour"}[1m])),
        0.001)
      / 1000)
   ```
1. The following query will return the Envoy memory usage per thousand requests per second:
   ```
   sum(irate(container_memory_usage_bytes{container="envoy",pod=~"envoy-.*"}[1m]))
   / (round(
        sum(irate(
          envoy_http_downstream_rq_total{namespace="projectcontour"}[1m])),
        0.001)
      / 1000)
   ```

# Control Plane Latency

The path from making a configuration change using the CF CLI to that change
being applied in Envoy has a series of steps. It is recommended to monitor each
step separately in order to ensure that control plane latency is not too high
overall and to make fixing latency problems easier. This section will cover
metrics relevant to monitoring each step.

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
The Route Controller consumes Route CRs and outputs Contour configuration as other
CRs. There are no metrics output by Route Controller at this time, so the most
relevant metrics are emitted by the K8s API.


## Contour Metrics

Contour is responsible for converting `HTTPProxy` objects into envoy config. You
can check its performance and health with these metrics

Number of invalid `HTTPProxy` objects:
```
contour_httpproxy_invalid_total
```

Update operations by kind of update:
```
avg(rate(contour_eventhandler_operation_total{kind=~".*", op=~".*"}[1m])) by (op,kind)
```
