load("@ytt:data", "data")

def minio_enabled():
  return data.values.blobstore.endpoint == "http://cf-blobstore-minio.cf-blobstore.svc.cluster.local:9000"
end
