output "get-credentials_command" {
  value = "gcloud container clusters get-credentials --zone ${var.zone} gke-cluster-consulpeering"
}
