resource "google_dns_record_set" "wildcard" {
  name = "*.${var.env_dns_domain}."
  project = var.project

  type = "A"
  ttl  = 300

  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_address.lb_static_ip.address]
}

resource "google_dns_record_set" "apps_wildcard" {
  name = "*.apps.${var.env_dns_domain}."
  project = var.project

  type = "A"
  ttl  = 300

  managed_zone = var.dns_zone_name

  rrdatas = [google_compute_address.lb_static_ip.address]
}