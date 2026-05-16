# =============================================================================
# Virtual Machines — all on m910q
#
# Import commands:
#   terraform import proxmox_virtual_environment_vm.windows10 m910q/151
#   terraform import proxmox_virtual_environment_vm.arrsuite  m910q/204
# =============================================================================

# --- Windows 10 (VM 151) ---
resource "proxmox_virtual_environment_vm" "windows10" {
  node_name   = var.target_node
  vm_id       = 151
  name        = "Windows10"
  description = "Windows 10 desktop VM"
  tags        = ["desktop"]

  # TODO: verify values after import
  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    size         = 64
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "win10"
  }

  started = true
}

# --- Arr-Suite (VM 204) ---
# Docker host running the media management stack
# Compose files are in ../docker/
resource "proxmox_virtual_environment_vm" "arrsuite" {
  node_name   = var.target_node
  vm_id       = 204
  name        = "Arr-Suite"
  description = "Docker host for arr stack (Sonarr, Radarr, Prowlarr, Bazarr, qBittorrent)"
  tags        = ["media", "docker"]

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    size         = 32
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26" # Linux 2.6+ kernel
  }

  started = true
}
