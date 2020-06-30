load("@ytt:data", "data")

def cfdb_enabled():
  return len(data.values.uaa.database.host) == 0 or len(data.values.capi.database.host) == 0
end
