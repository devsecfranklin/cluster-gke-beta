data "google_client_config" "default" {}

# Gets the current version of Kubernetes engine
data "google_container_engine_versions" "gke_version" {
  location = var.zone
}

resource "google_compute_network" "vpc" {
  name                    = "${var.name}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = "false"
}

resource "google_compute_route" "egress_internet" {
  name             = "${var.name}-egress-internet"
  project          = var.project_id
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_router" "router" {
  name    = "${var.name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_subnetwork" "gke-subnet" {
  name                     = "${var.name}-gke-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc.name
  ip_cidr_range            = "10.99.0.0/24"
  private_ip_google_access = true

  /* A named secondary range is mandatory for a private cluster

  While using a secondary IP range is recommended in order to to separate
  cluster master and pod IPs, when using a network in the same project as
  your GKE cluster you can specify a blank range name to draw alias IPs
  from your subnetwork's primary IP range. If using a shared VPC network
  (a network from another GCP project) using an explicit secondary range is
  required.
  */
  secondary_ip_range = [
    {
      ip_cidr_range = "10.188.0.0/16"
      range_name    = "gke-secure-dev-lab-pods-7d18c33d"
    },
    {
      ip_cidr_range = "10.189.0.0/22"
      range_name    = "gke-secure-dev-lab-services-7d18c33d"
    },
  ]
}

resource "google_container_cluster" "dev_cluster" {
  name               = var.name
  project            = var.project_id
  location           = var.region
  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_subnetwork.gke-subnet.name
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c"
  ]

  remove_default_node_pool    = true
  initial_node_count          = 1
  enable_shielded_nodes       = true
  enable_intranode_visibility = true

  # https://github.com/hashicorp/terraform-provider-google/issues/5154
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    # This range must not overlap with any other ranges in use within 
    # the cluster's network, and it must be a /28 subnet. 
    master_ipv4_cidr_block = "10.253.0.0/28"
  }

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "68.38.137.81/32"
      display_name = "franklin-lab"
    }
    cidr_blocks {
      cidr_block   = "34.136.90.64/32"
      display_name = "panorama-two"
    }
    cidr_blocks {
      cidr_block   = "34.134.31.136/32"
      display_name = "panorama-three"
    }
    cidr_blocks {
      cidr_block   = "50.211.230.249/32"
      display_name = "ds-office-franklin"
    }
    cidr_blocks {
      cidr_block   = "75.70.99.60/32"
      display_name = "franklin-denver"
    }
  }

  network_policy {
    # In GKE this also enables the ip masquerade agent
    # https://cloud.google.com/kubernetes-engine/docs/how-to/ip-masquerade-agent
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    // Enable network policy (Calico) as an addon.
    network_policy_config {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    // Provide the ability to scale pod replicas based on real-time metrics
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "memory"
      minimum       = 10
      maximum       = 100
    }
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 10
    }

    auto_provisioning_defaults {
      service_account = var.service_account_terraform
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }
}

resource "google_container_node_pool" "dev_nodes" {
  name     = "dev-node-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.dev_cluster.name

  node_count = var.gke_num_nodes

  autoscaling {
    min_node_count = 2
    max_node_count = 15
  }

  node_config {
    // COS or COS_containerd are ideal here.
    image_type = "COS"
    // using pd-ssd's is recommended for pods that do any scratch disk operations.
    disk_type = "pd-ssd"

    // https://tfsec.dev/docs/google/GCP012/
    // Use a custom service account for this node pool.  Be sure to grant it
    // a minimal amount of IAM roles and not Project Editor like the default SA.
    //service_account = var.service_account_terraform

    // Use the default/minimal oauth scopes to help restrict the permissions to
    // only those needed for GCR and stackdriver logging/monitoring/tracing needs.
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.name
      app = "dev-betai" // label will be used for node selection in CI pipelines
    }

    preemptible  = false
    machine_type = var.node_machine_type
    tags         = ["gke-node", "${var.name}-dev-node"]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Fix broken nodes automatically and keep them updated with the control plane.
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

module "tekton" {
  source = "github.com/cloud-native-toolkit/terraform-tools-tekton"

  cluster_type               = "kubernetes"
  cluster_config_file_path   = "."
  cluster_ingress_hostname   = "ingress-tkn"
  tools_namespace            = var.tekton_namespace
  tekton_dashboard_namespace = var.tekton_namespace

}
