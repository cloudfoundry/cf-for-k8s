# Developing components on cf-for-k8s

# Running Smoke Tests
```
cd tests/smoke
SMOKE_TEST_API_ENDPOINT=https://api.system.cf.example.com SMOKE_TEST_USERNAME=admin SMOKE_TEST_PASSWORD=cfadminpassword SMOKE_TEST_APPS_DOMAIN=apps.cf.example.com ginkgo ./...
```
