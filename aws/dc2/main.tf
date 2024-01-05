locals {
  cluster_name = "learn-clusterpeer-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
