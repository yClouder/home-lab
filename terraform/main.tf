terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # Self-signed cert on Proxmox

  ssh {
    agent    = true
    username = "root"

    node {
      name    = "m910q"
      address = "192.168.0.200"
    }

    node {
      name    = "m70q"
      address = "192.168.0.220"
    }
  }
}
