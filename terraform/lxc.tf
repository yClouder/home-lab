# =============================================================================
# LXC Containers
#
# Import commands:
#   terraform import proxmox_virtual_environment_container.jellyfin  m910q/201
#   terraform import proxmox_virtual_environment_container.npm       m910q/202
#   terraform import proxmox_virtual_environment_container.rustdesk  m910q/203
#   terraform import proxmox_virtual_environment_container.couchdb   m910q/205
#   terraform import proxmox_virtual_environment_container.minecraft m70q/105
# =============================================================================

# --- Jellyfin (LXC 201) ---
# Media server with VAAPI hardware transcoding (Intel HD 630)
# NAS media accessed via Proxmox bind mount
resource "proxmox_virtual_environment_container" "jellyfin" {
  node_name = var.target_node
  vm_id     = 201
  description = "Jellyfin media server"
  tags      = ["media"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "ubuntu"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 12000
    swap      = 512
  }

  disk {
    datastore_id = "StorageOne"
    size         = 8
  }

  # GPU passthrough — card1 (video node) + renderD128 (render node)
  device_passthrough {
    deny_write = false
    gid        = 44
    mode       = "0660"
    path       = "/dev/dri/card1"
    uid        = 0
  }

  device_passthrough {
    deny_write = false
    gid        = 104
    mode       = "0660"
    path       = "/dev/dri/renderD128"
    uid        = 0
  }

  features {
    nesting = true
    keyctl  = true
    fuse    = true
    mount   = ["nfs"]
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "jellyfin"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "auto"
      }
    }
  }

  # NAS bind mount — Proxmox host /mnt/nas/media -> LXC /mnt/nas/media
  mount_point {
    volume = "/mnt/nas/media"
    path   = "/mnt/nas/media"
  }

  started      = true
  unprivileged = true

  lifecycle {
    ignore_changes = [description, operating_system[0].template_file_id]
  }
}

# --- Nginx Proxy Manager (LXC 202) ---
# Reverse proxy handling all external traffic (ports 80/443)
resource "proxmox_virtual_environment_container" "npm" {
  node_name = var.target_node
  vm_id     = 202
  description = "Reverse proxy handling all internal traffic (ports 80/443)"
  tags      = ["network"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  features {
    nesting = true
    keyctl  = true
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "nginxproxymanager"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  started      = true
  unprivileged = true

  lifecycle {
    ignore_changes = [description, operating_system[0].template_file_id]
  }
}

# --- RustDesk (LXC 203) ---
# Self-hosted remote desktop server
resource "proxmox_virtual_environment_container" "rustdesk" {
  node_name = var.target_node
  vm_id     = 203
  description = "Self-hosted remote desktop server"
  tags      = ["remote-desktop"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 2
  }

  features {
    nesting = true
    keyctl  = true
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "rustdeskserver"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  started      = true
  unprivileged = true

  lifecycle {
    ignore_changes = [description, operating_system[0].template_file_id]
  }
}

# --- CouchDB / Obsidian LiveSync (LXC 205) ---
# CouchDB backend for Obsidian LiveSync plugin (self-hosted sync)
# Web UI: port 5984 (_utils)
resource "proxmox_virtual_environment_container" "couchdb" {
  node_name   = var.target_node
  vm_id       = 205
  description = "CouchDB for Obsidian LiveSync"
  tags        = ["notes"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
    swap      = 256
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
  }

  features {
    nesting = true
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "couchdb"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  started      = true
  unprivileged = true

  lifecycle {
    ignore_changes = [description, operating_system[0].template_file_id]
  }
}

# --- Minecraft (LXC 105) ---
# Runs on m70q
resource "proxmox_virtual_environment_container" "minecraft" {
  node_name = "m70q"
  vm_id     = 105
  description = "Minecraft server running on m70q"
  tags      = ["games"]

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
    type             = "debian"
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
    swap      = 1024
  }

  disk {
    datastore_id = "local-lvm"
    size         = 40
  }

  features {
    nesting = true
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "minecraft"
    dns {
      servers = ["8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = "192.168.0.210/24"
        gateway = var.gateway
      }
    }
  }

  started      = true
  unprivileged = true

  lifecycle {
    ignore_changes = [operating_system[0].template_file_id]
  }
}
