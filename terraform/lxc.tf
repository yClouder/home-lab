# =============================================================================
# LXC Containers — all on m910q
#
# These definitions represent your existing containers. After importing them
# into Terraform state, run `terraform plan` to see any drift between these
# definitions and the actual Proxmox config, then adjust the .tf files to match.
#
# Import commands:
#   terraform import proxmox_virtual_environment_container.jellyfin  m910q/201
#   terraform import proxmox_virtual_environment_container.npm       m910q/202
#   terraform import proxmox_virtual_environment_container.rustdesk  m910q/203
#   terraform import proxmox_virtual_environment_container.minecraft m910q/105
# =============================================================================

# --- Jellyfin (LXC 201) ---
# Media server with VAAPI hardware transcoding (Intel HD 630)
# NAS media accessed via Proxmox bind mount
resource "proxmox_virtual_environment_container" "jellyfin" {
  node_name   = var.target_node
  vm_id       = 201
  description = "Jellyfin media server"
  tags        = ["media"]

  # TODO: verify template matches what was originally used
  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  # TODO: verify values after import — run `terraform plan` to see drift
  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "jellyfin"

    ip_config {
      ipv4 {
        address = "192.168.0.201/24"
        gateway = var.gateway
      }
    }
  }

  features {
    nesting = true
  }

  # NAS bind mount — Proxmox host /mnt/nas/media -> LXC /mnt/nas/media
  mount_point {
    volume = "/mnt/nas/media"
    path   = "/mnt/nas/media"
  }

  started      = true
  unprivileged = true
}

# --- Nginx Proxy Manager (LXC 202) ---
# Reverse proxy handling all external traffic (ports 80/443)
resource "proxmox_virtual_environment_container" "npm" {
  node_name   = var.target_node
  vm_id       = 202
  description = "Nginx Proxy Manager - reverse proxy"
  tags        = ["network"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "npm"

    ip_config {
      ipv4 {
        address = "192.168.0.202/24"
        gateway = var.gateway
      }
    }
  }

  started      = true
  unprivileged = true
}

# --- RustDesk (LXC 203) ---
# Self-hosted remote desktop server
resource "proxmox_virtual_environment_container" "rustdesk" {
  node_name   = var.target_node
  vm_id       = 203
  description = "RustDesk remote desktop server"
  tags        = ["tools"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "rustdesk"

    ip_config {
      ipv4 {
        address = "192.168.0.203/24"
        gateway = var.gateway
      }
    }
  }

  started      = true
  unprivileged = true
}

# --- Minecraft (LXC 105) ---
resource "proxmox_virtual_environment_container" "minecraft" {
  node_name   = var.target_node
  vm_id       = 105
  description = "Minecraft server"
  tags        = ["games"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    size         = 16
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "minecraft"

    ip_config {
      ipv4 {
        address = "192.168.0.105/24"
        gateway = var.gateway
      }
    }
  }

  started      = true
  unprivileged = true
}
