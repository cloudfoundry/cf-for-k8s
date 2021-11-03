resource "google_container_cluster" "primary" {
  name               = var.env_name
  location           = var.zone
  initial_node_count = var.node_count

  network = var.network_name
  subnetwork = var.subnet_name

  release_channel {
    channel = var.release_channel
  }

  maintenance_policy {
    recurring_window {
        start_time = "2019-01-01T00:00:00-07:00"
        end_time = "2019-01-01T06:00:00-07:00"
        recurrence = "FREQ=DAILY"
      }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  network_policy {
    enabled = true
  }

  node_config {
    machine_type = var.node_machine_type
    image_type = "COS"
    service_account = google_service_account.node_service_account.email

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      "cluster_management_overload_env_name" = var.env_name
    }
  }
}

resource "google_service_account" "node_service_account" {
  project = var.project
  account_id   = "${var.env_name}-sa"
  display_name = "${var.env_name} Service Account"
}

resource "google_project_iam_member" "node_service_member_iam_log_writer" {
  project = var.project
  role = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_member_iam_monitoring_viewer" {
  project = var.project
  role = "roles/monitoring.viewer"
  member = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_member_iam_monitoring_metric_writer" {
  project = var.project
  role = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_member_iam_storage_object_viewer" {
  project = var.project
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.node_service_account.email}"
}
