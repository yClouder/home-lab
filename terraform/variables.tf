variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint (e.g. https://192.168.0.200:8006)"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in format: USER@REALM!TOKENID=UUID"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Default Proxmox node name"
  type        = string
  default     = "m910q"
}

variable "gateway" {
  description = "Default gateway for guests"
  type        = string
  default     = "192.168.0.1"
}
