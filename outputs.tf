output "vpc_network_name" {
  value = google_compute_network.hogwarts_vpc.name
}

output "app_server_internal_ip" {
  value = google_compute_instance.app_server_vm.network_interface[0].network_ip
}

output "database_internal_ip" {
  value = google_compute_instance.database_vm.network_interface[0].network_ip
}

output "bigquery_dataset_id" {
  value = google_bigquery_dataset.hogwarts_siem_logs.dataset_id
}

output "compliance_bucket_url" {
  value = google_storage_bucket.hogwarts_compliance_audit_vault.url
}

output "log_sink_writer_identity" {
  value = google_logging_project_sink.hogwarts_security_log_link.writer_identity
}