resource "google_project_service" "svc" {
  service = "${each.value}.googleapis.com"

  disable_dependent_services = true

  for_each = toset([
    "container",
  ])
}

resource "google_container_cluster" "gke-cluster-consulpeering" {
  name = "gke-cluster-consulpeering"
  location = var.zone
  initial_node_count = 3
  deletion_protection = false

  depends_on = [
    google_project_service.svc["container"]
  ]
}

data "google_client_config" "provider" {}

data "google_container_cluster" "gke-cluster-consulpeering" {
  name     = "gke-cluster-consulpeering"
  location = var.zone

  depends_on = [ google_container_cluster.gke-cluster-consulpeering ]
}

module "gke_auth" {
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = var.project
  cluster_name         = "gke-cluster-consulpeering"
  location             = var.zone
  use_private_endpoint = true

  depends_on = [ google_container_cluster.gke-cluster-consulpeering ]
}
