load("@ytt:data", "data")

def quarks_secret_enabled():
  return data.values.experimental.quarks_secret.enable == True
end
