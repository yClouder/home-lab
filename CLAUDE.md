# Home Lab Project

## Overview
Home lab infrastructure as code — Terraform for Proxmox VM/LXC provisioning, Docker Compose for application stacks. My objective is using this repo for controlling my applications running on my Proxmox cluster.

## Architecture
```
Internet → Nginx Proxy Manager LXC (80/443) → Arr-Suite VM (204)
                                             → Jellyfin LXC (201)
                                             → Windows 10 VM (151)
                                             → Other LXCs

Unraid NAS (192.168.0.101) ← NFS → Arr-Suite VM (/mnt/nas)
                            ← NFS → Proxmox (/mnt/nas) → bind mount → Jellyfin LXC (/mnt/nas/media)
```

## Proxmox Cluster
Two-node cluster:

| | **m910q** (192.168.0.200) | **m70q** (192.168.0.220) |
|---|---|---|
| **SSH** | `ssh m910q` (root) | `ssh m70q` (root) |
| **CPU** | i5-7500T (4C/4T, 3.3GHz boost) | i3-10100T (4C/8T, 3.8GHz boost) |
| **RAM** | 32 GB | 8 GB |
| **Storage** | 240GB SSD (boot) + 1TB NVMe | 128GB NVMe (boot only) |
| **GPU** | Intel HD 630 | Intel UHD 630 |
| **PVE** | 8.4.5 | 8.4.17 |
| **Guests** | VM 151, 204; LXC 105, 201, 202, 203 | None |

## Project Structure
- `docker/` - Docker Compose stacks (arr suite, deployed on VM 204)
  - `docker-compose.yml` - Main compose file (watchtower + includes)
  - `arr-compose.yml` - Arr stack (Radarr, Sonarr, Prowlarr, Bazarr)
  - `bittorrent-compose.yml` - qBittorrent
  - `flaresolverr-compose.yml` - FlareSolverr (CAPTCHA solver for Prowlarr)
  - `secrets/` - Docker secrets directory
  - `env/` - Environment files
- `terraform/` - Proxmox infrastructure as code
  - `main.tf` - Provider configuration
  - `variables.tf` - Input variables
  - `lxc.tf` - LXC container definitions (201, 202, 203, 105)
  - `vm.tf` - VM definitions (151, 204)
  - `outputs.tf` - Output values
  - `terraform.tfvars.example` - Example variable values (copy to terraform.tfvars)

## Services
- **qBittorrent**: Torrent client (port 8088)
- **Sonarr**: TV show management (port 8989)
- **Radarr**: Movie management (port 7878)
- **Prowlarr**: Indexer manager (port 9696)
- **Bazarr**: Subtitle management (port 6767)
- **FlareSolverr**: CAPTCHA solver (port 8191)
- **Watchtower**: Auto-updates

## Ports Exposed
- 8088: qBittorrent web UI
- 8989: Sonarr web UI
- 7878: Radarr web UI
- 9696: Prowlarr web UI
- 6767: Bazarr web UI
- 8191: FlareSolverr

## Commands
- Docker: `cd docker && docker compose up -d` to start all services
- Terraform: `cd terraform && terraform init` / `terraform plan` / `terraform apply`
- Check individual compose files for specific service management

## Storage Configuration
Storage is split between local disk (app configs) and NAS (media data).

- **NAS**: Unraid at `192.168.0.101`, NFS export `/mnt/user/media` mounted to `/mnt/nas`
- **Local disk**: `/opt/docker_data` for app config/database files (performance-sensitive)
- **Environment variables**:
  - `NAS_MEDIA_PATH=/mnt/nas/media` — media data on NAS
  - `DOCKER_DATA_PATH=/opt/docker_data` — local app configs

- **NAS Directory Structure** (`/mnt/nas/media/`):
  ```
  /mnt/nas/media/
  ├── torrents/              # qBittorrent downloads
  ├── movies/                # Radarr managed movies
  └── tv/                    # Sonarr managed TV shows
  ```

- **Local Directory Structure** (`/opt/docker_data/`):
  ```
  /opt/docker_data/
  ├── sonarr/                # Sonarr database
  ├── radarr/                # Radarr database
  ├── prowlarr/              # Indexer configs
  ├── bazarr/                # Bazarr database
  ├── bittorrent/            # qBittorrent settings
  └── flaresolverr/          # FlareSolverr cache
  ```

## Deployment
- The repo lives at `~/repos/home-lab` on the miniPC (arrsuite)
- SSH alias: `ssh arrsuite` (user: yclouder, host: 192.168.0.204)
- Workflow: edit locally → commit & push → SSH pull & `cd docker && docker compose up -d`
- Terraform: run locally against Proxmox API (no need to SSH)
- sudo requires a TTY/password on arrsuite — run privileged commands manually

## NAS Mount Details
- Unraid NAS at `192.168.0.101`, NFS export `/mnt/user/media`
- Switched from CIFS to NFS — fixes inotify for Jellyfin library monitoring and avoids stale mounts
- **miniPC (arrsuite)** fstab: `192.168.0.101:/mnt/user/media /mnt/nas nfs defaults,_netdev,soft,timeo=100,rsize=131072,wsize=131072 0 0`
- **Proxmox (m910q)** fstab: `192.168.0.101:/mnt/user/media /mnt/nas nfs defaults,_netdev,soft,timeo=100,rsize=131072,wsize=131072 0 0`
- **Jellyfin LXC (201)**: NAS accessed via Proxmox bind mount (`mp1: /mnt/nas/media,mp=/mnt/nas/media` in LXC config)

## Jellyfin
- SSH alias: `ssh jellyfin` (root, LXC 201 on Proxmox)
- Runs as native systemd service (not Docker)
- Media libraries: `/mnt/nas/media/movies` and `/mnt/nas/media/tv`
- **Hardware transcoding**: VAAPI enabled (switched from QSV), Intel HD 630 GPU passed through (`/dev/dri/renderD128`)
- GPU permissions: `renderD128` must be owned by `render` group (fix with `chgrp render /dev/dri/renderD128` after LXC restart)
- **Subtitles**: Embedded subs extracted as separate streams (no burn-in). Also uses Bazarr external `.srt` files (pt-BR primary, English fallback)

## Container Volume Mappings
All services share the `media` volume which maps `${NAS_MEDIA_PATH}` → `/media` inside containers.
- **qBittorrent**: downloads to `/media/torrents/`
- **Sonarr**: root folder `/media/tv/`
- **Radarr**: root folder `/media/movies/`
- **Prowlarr/Bazarr**: access full `/media/` root

## Service Connections
- **Prowlarr** syncs indexers to Sonarr and Radarr (via API keys)
- **FlareSolverr** used by Prowlarr for Cloudflare-protected indexers (tag-based, `http://flaresolverr:8191`)
- **qBittorrent** is the download client for Sonarr/Radarr (host: `bittorrent`, port: `8088`)
- **Bazarr** fetches subtitles for Sonarr/Radarr content (pt-BR primary, English fallback)
- **Bazarr providers**: OpenSubtitles.com, SubDL

## Sonarr/Radarr Custom Formats
Configured to prefer quality releases via scoring:
- **Dual Audio** (+100) — prefer releases with multiple audio tracks
- **x265/HEVC** (+50) — prefer smaller file sizes
- **BR-DISK** (-1000) — avoid raw disc rips
- **LQ Groups** (-500) — avoid low quality release groups
- **SubsPlease** (+50, Sonarr only) — reliable anime releases
- **Erai-raws** (+50, Sonarr only) — good anime multi-sub releases

## Transcoding & Subtitles
- Intel HD 630 GPU used by Jellyfin (LXC 201) via VAAPI
- After any LXC restart, GPU permissions reset — fix with `chgrp render /dev/dri/renderD128`
- **Embedded subtitles** force video transcoding (burn-in) which is resource-intensive
  - Jellyfin: extracts embedded subs as separate streams (avoids burn-in); use VAAPI not QSV (QSV crashes with subtitle burn-in)
- **External SRT subtitles** (from Bazarr) don't require transcoding — player renders them as overlay
- inotify file monitoring works over NFS but **not** over CIFS — this was the reason for switching to NFS

## Backups
- **Strategy**: Proxmox vzdump backs up all VMs/LXCs to Unraid NAS
- **NAS share**: `backups` on Unraid, NFS export at `192.168.0.101:/mnt/user/backups`
- **Proxmox storage**: `Nas-Backup` (NFS, content type: VZDump backup file)
- **Schedule**: Weekly, Sunday at 1:00 AM
- **Guests**: VM 151 (Windows10), VM 204 (Arr-Suite), LXC 201 (Jellyfin), 202 (NPM), 203 (RustDesk), 105 (Minecraft)
- **Mode**: Stop
- **Compression**: ZSTD
- **Retention**: Keep last 4 backups (1 month of weekly backups)
- Media files on the NAS are NOT backed up by this — only VM/LXC configs + app data

## Notes
- Gluetun/VPN removed — qBittorrent runs without VPN currently
- Unpackerr disabled due to API key reading issue
- No local reverse proxy - handled by external Nginx Proxy Manager LXC
- Secrets are stored in Docker secrets format
- The `dev` branch is the active working branch (miniPC tracks `dev`)
- LXCs can't mount NFS/CIFS directly — must use Proxmox bind mounts
