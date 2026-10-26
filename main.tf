# 1. Custom VPC Network
resource "google_compute_network" "hogwarts_vpc" {
  name                    = "hogwarts-vpc"
  auto_create_subnetworks = false
}

# 2. Private Subnets
resource "google_compute_subnetwork" "web_app_subnet" {
  name          = "web-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.hogwarts_vpc.id
}

resource "google_compute_subnetwork" "data_subnet" {
  name          = "data-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.hogwarts_vpc.id
}

# 3. Cloud Router & NAT for Outbound Private Access
resource "google_compute_router" "hogwarts_cloud_router" {
  name    = "hogwarts-cloud-router"
  region  = "us-central1"
  network = google_compute_network.hogwarts_vpc.id
}

resource "google_compute_router_nat" "the_owlery_nat" {
  name                               = "the-owlery-nat"
  router                             = google_compute_router.hogwarts_cloud_router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.web_app_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# 4. IAP Firewall Rule for Secure SSH
resource "google_compute_firewall" "allow_iap_ssh_ward" {
  name    = "allow-iap-ssh-ward"
  network = google_compute_network.hogwarts_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-accessible"]
}

# 5. Private Compute Instances
resource "google_compute_instance" "app_server_vm" {
  name         = "app-server-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = ["iap-accessible"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.hogwarts_vpc.id
    subnetwork = google_compute_subnetwork.web_app_subnet.id
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      attached_disk,
    ]
  }
}

resource "google_compute_instance" "database_vm" {
  name         = "database-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = ["iap-accessible"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.hogwarts_vpc.id
    subnetwork = google_compute_subnetwork.data_subnet.id
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      attached_disk,
    ]
  }
}

# 6. BigQuery Dataset for SIEM Logs
resource "google_bigquery_dataset" "hogwarts_siem_logs" {
  dataset_id                 = "hogwarts_siem_logs"
  friendly_name              = "Hogwarts SIEM Audit Logs"
  description                = "Centralized sink for GCP Cloud Audit logs"
  location                   = "US-CENTRAL1"
  delete_contents_on_destroy = false
}

# 7. Compliance Cloud Storage Bucket with WORM Lock
resource "google_storage_bucket" "hogwarts_compliance_audit_vault" {
  name                        = "hogwarts-compliance-audit-vault"
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  retention_policy {
    retention_period = 86400
    is_locked        = true
  }
}

# 8. Log Router Sink to BigQuery
resource "google_logging_project_sink" "hogwarts_security_log_link" {
  name                   = "hogwarts-security-log-link"
  destination            = "bigquery.googleapis.com/projects/hogwarts-castle-defense/datasets/hogwarts_siem_logs"
  filter                 = "logName=\"projects/hogwarts-castle-defense/logs/cloudaudit.googleapis.com%2Factivity\" OR logName=\"projects/hogwarts-castle-defense/logs/cloudaudit.googleapis.com%2Fdata_access\""
  unique_writer_identity = true
}

# 9. Grant BigQuery Writer permissions to the Log Sink service account
resource "google_project_iam_member" "log_sink_bq_writer" {
  project = "hogwarts-castle-defense"
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.hogwarts_security_log_link.writer_identity
}