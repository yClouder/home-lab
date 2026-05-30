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
  description = "Windows 10 VM running on m910q for general use"
  tags        = ["general-use"]

  bios    = "ovmf"
  machine = "pc-q35-9.2+pve1"
  on_boot = false

  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores   = 4
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  efi_disk {
    datastore_id      = "StorageOne"
    type              = "4m"
    pre_enrolled_keys = true
  }

  disk {
    datastore_id = "StorageOne"
    size         = 64
    interface    = "ide0"
    file_format  = "qcow2"
  }

  tpm_state {
    datastore_id = "StorageOne"
    version      = "v2.0"
  }

  network_device {
    bridge   = "vmbr0"
    model    = "e1000"
    firewall = true
  }

  operating_system {
    type = "win11"
  }

  boot_order = ["ide0", "net0"]

  started = true

  # Windows VM lifecycle is user-managed (started/stopped manually) and the
  # live machine type includes ",viommu=virtio" which the provider rejects
  # as a valid value. Ignore both so TF never tries to reconcile them.
  lifecycle {
    ignore_changes = [machine, started]
  }
}

# --- Arr-Suite (VM 204) ---
# Docker host running the media management stack
# Compose files are in ../docker/
resource "proxmox_virtual_environment_vm" "arrsuite" {
  node_name   = var.target_node
  vm_id       = 204
  name        = "Arr-Suite"
  description = "Docker host running the media management stack"
  tags        = ["media"]

  on_boot = true

  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores   = 2
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "StorageOne"
    size         = 32
    interface    = "scsi0"
    file_format  = "qcow2"
    iothread     = true
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["scsi0", "net0"]

  started = true
}
