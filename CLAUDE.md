# Home Lab Project

## Overview
This is a Docker-based home lab setup with multiple services organized in separate compose files. My objective is using this repo for controlling my applications running on my Proxmox server.

## Architecture
```
Internet → Nginx Proxy Manager LXC (80/443) → miniPC (Arr + BitTorrent services)
                                             → Jellyfin LXC (101)
                                             → Other LXCs

Unraid NAS (192.168.0.101) ← CIFS → miniPC (/mnt/nas)
                            ← CIFS → Proxmox (/mnt/nas) → bind mount → Jellyfin LXC (/mnt/nas/media)
```

## Project Structure
- `docker-compose.yml` - Main compose file (watchtower + includes)
- `arr-compose.yml` - Arr stack (Radarr, Sonarr, Prowlarr, Bazarr)
- `bittorrent-compose.yml` - qBittorrent
- `flaresolverr-compose.yml` - FlareSolverr (CAPTCHA solver for Prowlarr)
- `secrets/` - Docker secrets directory
- `env/` - Environment files

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
- Use `docker compose up -d` to start all services
- Check individual compose files for specific service management

## Storage Configuration
Storage is split between local disk (app configs) and NAS (media data).

- **NAS**: Unraid at `192.168.0.101`, SMB share `media` mounted via CIFS to `/mnt/nas`
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
- Workflow: edit locally → commit & push → SSH pull & `docker compose up -d`
- sudo requires a TTY/password on arrsuite — run privileged commands manually

## NAS Mount Details
- Unraid NAS at `192.168.0.101`, SMB share named `media`
- CIFS mount requires `vers=3.0` (default version hangs)
- NFS is **not** enabled on the NAS — must use CIFS/SMB
- **miniPC (arrsuite)** fstab: `//192.168.0.101/media /mnt/nas cifs defaults,_netdev,vers=3.0,uid=1000,gid=1000,username=arrsuite,password=arrsuite 0 0`
- **Proxmox** fstab: `//192.168.0.101/media /mnt/nas cifs defaults,_netdev,vers=3.0,uid=100000,gid=100000,username=arrsuite,password=arrsuite 0 0` (uid 100000 for unprivileged LXC mapping)
- **Jellyfin LXC (101)**: NAS accessed via Proxmox bind mount (`mp1: /mnt/nas/media,mp=/mnt/nas/media` in LXC config)

## Jellyfin
- SSH alias: `ssh jellyfin` (root, LXC 101 on Proxmox)
- Runs as native systemd service (not Docker)
- Media libraries should point to `/mnt/nas/media/movies` and `/mnt/nas/media/tv`
- Old Proxmox disk still mounted at `/mnt/media` (legacy, data being migrated to NAS)

## Container Volume Mappings
- **qBittorrent**: `/media` → `${NAS_MEDIA_PATH}/torrents` (saves to `/media/` inside container)
- **Sonarr/Radarr/Prowlarr/Bazarr**: `/media` → `${NAS_MEDIA_PATH}` (full NAS media root)

## Notes
- Gluetun/VPN removed — qBittorrent runs without VPN currently
- Unpackerr disabled due to API key reading issue
- No local reverse proxy - handled by external Nginx Proxy Manager LXC
- Secrets are stored in Docker secrets format
- The `dev` branch is the active working branch (miniPC tracks `dev`)
