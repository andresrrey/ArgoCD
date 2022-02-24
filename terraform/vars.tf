variable "gcp_zone" {
  type = string
  default = "us-east1-b"
}

variable "gcp_region" {
  type = string
  default = "us-east1"
}

variable "gcp_project_id" {
  type = string
  default = "gcp-bench"
}

variable "gke_master_ipv4_cidr_block" {
  type    = string
  default = "172.23.0.0/28"
}

variable "authorized_source_ranges" {
  type        = list(string)
  description = "Addresses or CIDR blocks which are allowed to connect to GKE API Server."
}
