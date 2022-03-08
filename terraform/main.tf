terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }

  backend "gcs" {
    bucket = "andresrrey_argocd"
    prefix = "terraform-state"
  }
}

provider "google" {
  project = var.gcp_project_id
  region = var.gcp_region
  zone = var.gcp_zone
}

provider "kubernetes" {}

provider "google-beta" {
  project = var.gcp_project_id
  region = var.gcp_region
  zone = var.gcp_zone
}

resource "google_compute_network" "custom" {
  name                    = "custom"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "web" {
  name          = "web"
  ip_cidr_range = "10.10.10.0/24"
  network       = google_compute_network.custom.id
  region        = var.gcp_region

  secondary_ip_range  = [
    {
        range_name    = "services"
        ip_cidr_range = "10.10.11.0/24"
    },
    {
        range_name    = "pods"
        ip_cidr_range = "10.1.0.0/20"
    }
  ]

  private_ip_google_access = true
}

resource "google_compute_address" "web" {
  name    = "web"
  region  = var.gcp_region
}

resource "google_compute_router" "web" {
  name    = "web"
  network = google_compute_network.custom.id
}

resource "google_compute_router_nat" "web" {
  name                               = "web"
  router                             = google_compute_router.web.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [ google_compute_address.web.self_link ]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.web.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on                         = [ google_compute_address.web ]
}

resource "google_compute_firewall" "web" {
  name    = "allow-only-authorized-networks"
  network = google_compute_network.custom.name

  allow {
    protocol = "tcp"
  }

  priority = 1000

  source_ranges = var.authorized_source_ranges
}

resource "google_container_cluster" "k8s" {
  provider = google-beta

  name = "k8s-cluster"
  location = var.gcp_region

  network                  = google_compute_network.custom.name
  subnetwork               = google_compute_subnetwork.web.id

  enable_autopilot = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
        for_each = var.authorized_source_ranges
        content {
            cidr_block = cidr_blocks.value
        }
    }
   }
}
