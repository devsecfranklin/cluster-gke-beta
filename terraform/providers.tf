provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone // provider level zone option, but needed in this case for oauth
  //impersonate_service_account = var.service_account_terraform
}

terraform {
  required_version = ">= 1.0.3"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.7.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.11.3"
    }
  }
  backend "gcs" {
    bucket = "cluster-gke-beta"
    prefix = "franklin-tf-state"
  }
}

provider "kubernetes" {
  host        = "https://${data.google_container_cluster.lab_cluster.endpoint}"
  config_path = "~/.kube/config"
}
