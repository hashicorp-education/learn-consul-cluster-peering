output "get-credentials_command" {
  value = "gcloud container clusters get-credentials --zone ${var.zone} dc1"
}
