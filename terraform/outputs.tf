output "lxc_ids" {
  description = "LXC container VM IDs"
  value = {
    jellyfin  = proxmox_virtual_environment_container.jellyfin.vm_id
    npm       = proxmox_virtual_environment_container.npm.vm_id
    rustdesk  = proxmox_virtual_environment_container.rustdesk.vm_id
    minecraft = proxmox_virtual_environment_container.minecraft.vm_id
  }
}

output "vm_ids" {
  description = "VM IDs"
  value = {
    windows10 = proxmox_virtual_environment_vm.windows10.vm_id
    arrsuite  = proxmox_virtual_environment_vm.arrsuite.vm_id
  }
}
