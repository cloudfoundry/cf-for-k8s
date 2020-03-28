resource "google_container_cluster" "primary" {
  provider           = google-beta
  name               = var.env_name
  location           = "us-central1-a"
  initial_node_count = 5

  release_channel {
    channel = "RAPID"
  }

  maintenance_policy {
    recurring_window {
        start_time = "2019-01-01T00:00:00-07:00"
        end_time = "2019-01-01T06:00:00-07:00"
        recurrence = "FREQ=DAILY"
      }
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    machine_type = "n1-standard-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      "cluster_management_overload_env_name" = var.env_name
    }
  }
}
