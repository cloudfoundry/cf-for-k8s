# Setting Up External Syslog Destinations

To send logs to an external destination via syslog you can setup app log destinations in your `cf-values.yml` file:

```yml
app_log_destinations:
#@overlay/append
- host: <hostname>
  port: <port_number>
  transport: <tls/tcp> #defaults to tls
  insecure_disable_tls_validation: <false/true> #defaults false
#@overlay/append
- host: <hostname>
  port: <port_number>
  transport: <tls/tcp> #defaults to tls
  insecure_disable_tls_validation: <false/true> #defaults false
```
