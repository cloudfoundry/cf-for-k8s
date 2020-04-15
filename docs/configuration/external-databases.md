# Using external databases

## Cloud controller database

You can use an external database for the cloud controller by providing following values:

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