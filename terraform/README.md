# Terraform Learning Guide — Proxmox Home Lab

Step-by-step guide to managing your Proxmox cluster with Terraform.

## Prerequisites

### 1. Install Terraform

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify
terraform -version
```

### 2. Create a Proxmox API Token

SSH into your Proxmox node and create a dedicated user + token:

```bash
ssh m910q

# Create a terraform user
pveum user add terraform@pve

# Create an API token (save the output — the secret is shown only once!)
pveum user token add terraform@pve terraform

# Grant permissions — Administrator role on /
pveum acl modify / --user terraform@pve --role Administrator
```

The output will look like:
```
┌──────────────┬──────────────────────────────────────┐
│ key          │ value                                │
├──────────────┼──────────────────────────────────────┤
│ full-tokenid │ terraform@pve!terraform              │
│ info         │ {"privsep":"1"}                      │
│ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
└──────────────┴──────────────────────────────────────┘
```

Your API token string is: `terraform@pve!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

> **Note**: You can scope permissions down later (e.g. only VM/LXC management).
> Starting with Administrator makes the learning process smoother.

### 3. Configure Your Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your real API token. This file is gitignored.

## Getting Started

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

This downloads the `bpg/proxmox` provider. You should see "Terraform has been successfully initialized!"

### Step 2: Plan (Dry Run)

```bash
terraform plan
```

Since nothing is imported yet, Terraform will want to **create** all resources.
Don't apply yet — you need to import your existing infrastructure first.

### Step 3: Import Existing Resources

Terraform doesn't know about your existing VMs/LXCs. You need to import them
so Terraform adopts management of them **without recreating** them.

Import each resource one at a time:

```bash
# LXC containers
terraform import proxmox_virtual_environment_container.jellyfin  m910q/201
terraform import proxmox_virtual_environment_container.npm       m910q/202
terraform import proxmox_virtual_environment_container.rustdesk  m910q/203
terraform import proxmox_virtual_environment_container.minecraft m910q/105

# VMs
terraform import proxmox_virtual_environment_vm.windows10 m910q/151
terraform import proxmox_virtual_environment_vm.arrsuite  m910q/204
```

After each import, the resource is added to Terraform's **state file** (`terraform.tfstate`).

### Step 4: Reconcile Drift

After importing, run plan again:

```bash
terraform plan
```

You'll likely see differences — the `.tf` files have placeholder values (CPU, RAM, disk)
that may not match your actual Proxmox config. For each difference:

1. Read the plan output carefully
2. Update the `.tf` file to match reality (or decide to change the resource)
3. Re-run `terraform plan` until you see **"No changes. Your infrastructure matches the configuration."**

This is the most important learning step. It teaches you how Terraform compares
desired state (your `.tf` files) with actual state (Proxmox).

### Step 5: Apply Changes

Once plan shows only changes you **want** to make:

```bash
terraform apply
```

Terraform shows the plan and asks for confirmation. Type `yes` to apply.

## Key Concepts

### State
- Terraform tracks what it manages in `terraform.tfstate` (gitignored, local)
- The state file maps your `.tf` resource names to real Proxmox IDs
- Never edit the state file by hand — use `terraform state` commands

### Plan → Apply Workflow
- `terraform plan` = "what would change?" (safe, read-only)
- `terraform apply` = "make the changes" (asks for confirmation)
- Always plan before apply. Read the plan output carefully.

### Import vs Create
- `terraform import` = "start managing an existing resource"
- `terraform apply` on a new resource = "create it from scratch"
- For your existing lab, import first, create new things later

### Resources vs Data Sources
- **Resources** (`resource "proxmox_virtual_environment_vm"`) = things Terraform creates/manages
- **Data sources** (`data "proxmox_virtual_environment_vms"`) = read-only lookups from Proxmox

## Day-to-Day Workflow

```
1. Edit .tf files (add a new LXC, change RAM, etc.)
2. terraform plan          — review what will change
3. terraform apply         — apply the changes
4. Commit .tf files to git — track your infrastructure in version control
```

## What's Next

Once you're comfortable with the basics:

- **Add SSH keys**: Use `proxmox_virtual_environment_file` to manage SSH public keys
- **Templates**: Create reusable LXC/VM templates with `proxmox_virtual_environment_download_file`
- **Cloud-init**: Automate VM bootstrapping (install Docker, configure NFS mounts, etc.)
- **Remote state**: Store `terraform.tfstate` remotely (e.g. S3/Minio) for safer state management
- **Modules**: Extract repeated patterns (e.g. a "standard LXC" module with your common settings)
- **m70q node**: Start provisioning guests on your second node

## Useful Commands

```bash
terraform fmt              # Auto-format .tf files
terraform validate         # Check syntax without connecting to Proxmox
terraform state list       # Show all managed resources
terraform state show <res> # Show details of one resource
terraform destroy          # Tear down everything (careful!)
terraform output           # Show output values
```

## Provider Documentation

Full resource reference for the bpg/proxmox provider:
https://registry.terraform.io/providers/bpg/proxmox/latest/docs
