output "get-credentials_command" {
  value = "gcloud container clusters get-credentials --zone ${var.zone} dc2"
}

output "rename-context_cmd" {
  value = "kubectl config rename-context gke_${var.project}_${var.zone}_dc2 dc2"
}