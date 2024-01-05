output "set-project_command" {
  value = "gcloud config set project ${var.project}"
}

output "get-credentials_command" {
  value = "gcloud container clusters get-credentials --zone ${var.zone} dc1"
}

output "rename-context_command" {
  value = "kubectl config rename-context gke_${var.project}_${var.zone}_dc1 dc1"
}