provider "google-beta" {
  credentials = file("/tmp/dw-js-service-account.json")
  project     = "cf-relint-greengrass"
  region      = "us-central1"
}
