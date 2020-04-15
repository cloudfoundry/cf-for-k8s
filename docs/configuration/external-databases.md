# Using external databases

## Cloud controller database

You can use an external database for the cloud controller by applying an overlay like

```yaml
#@data/values
---
capi:
  database:
    adapter: <postgres | mysql2>
    host: <host>
    port: <port>
    user: <user>
    password: <password>
    name: <database>
```