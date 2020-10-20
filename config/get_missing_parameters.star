def non_empty_string(value):
  return type(value) == "string" and len(value) > 0
end

def non_empty_array(value):
  return type(value) == "list" and len(value) > 0
end

requirements = {
   "app_domains": non_empty_array,
}

def is_present(values, param):
    parts = param.split('.')
    obj = values
    for p in parts[0:-1]:
        obj = getattr(obj, p, None)
    end
    if not hasattr(obj, parts[-1]):
      return False
    end
    value = getattr(obj, parts[-1])
    if param in requirements:
      return requirements[param](value)
    end
    return non_empty_string(value)
end

def is_missing(values, param):
    return not is_present(values, param)
end

# Useful command to build the list of required parameters:
# awk '-F|' '$4 == " Yes " { printf("%s\n", gensub(/\s+/, "", "g", $2)) }' docs/platform_operators/config-values.md

def get_missing_parameters(values):
    required_parameters = '''\
app_domains
app_registry.hostname
app_registry.password
app_registry.repository_prefix
app_registry.username
blobstore.secret_access_key
capi.cc_username_lookup_client_secret
capi.cf_api_controllers_client_secret
capi.database.encryption_key
capi.database.password
cf_admin_password
internal_certificate.ca
internal_certificate.crt
internal_certificate.key
system_certificate.crt
system_certificate.key
system_domain
uaa.admin_client_secret
uaa.database.password
uaa.encryption_key.passphrase
uaa.jwt_policy.signing_key
uaa.login.service_provider.certificate
uaa.login.service_provider.key
uaa.login_secret
workloads_certificate.crt
workloads_certificate.key'''.split("\n")
    return [param for param in required_parameters if is_missing(values, param)]
end
