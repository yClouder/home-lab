# Home Lab Project

## Overview
This is a Docker-based home lab setup with multiple services organized in separate compose files. My objective is using this repo for controlling my applications running on my Proxmox server.

## Architecture
```
Internet → Nginx Proxy Manager LXC (80/443) → miniPC (Arr + BitTorrent services)
                                             → Jellyfin LXC (101)
                                             → Other LXCs

Unraid NAS (192.168.0.101) ← NFS → miniPC (/mnt/nas)
                            ← NFS → Proxmox (/mnt/nas) → bind mount → Jellyfin LXC (/mnt/nas/media)
                                                        → bind mount → Plex LXC (/mnt/nas/media)
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
- Workflow: edit locally → commit & push → SSH pull & `docker compose up -d`
- sudo requires a TTY/password on arrsuite — run privileged commands manually

## NAS Mount Details
- Unraid NAS at `192.168.0.101`, NFS export `/mnt/user/media`
- Switched from CIFS to NFS — fixes inotify for Jellyfin library monitoring and avoids stale mounts
- **miniPC (arrsuite)** fstab: `192.168.0.101:/mnt/user/media /mnt/nas nfs defaults,_netdev,soft,timeo=100,rsize=131072,wsize=131072 0 0`
- **Proxmox** fstab: `192.168.0.101:/mnt/user/media /mnt/nas nfs defaults,_netdev,soft,timeo=100,rsize=131072,wsize=131072 0 0`
- **Jellyfin LXC (101)**: NAS accessed via Proxmox bind mount (`mp1: /mnt/nas/media,mp=/mnt/nas/media` in LXC config)
- **Plex LXC (104)**: NAS accessed via Proxmox bind mount (`mp1: /mnt/nas/media,mp=/mnt/nas/media` in LXC config)

## Plex
- SSH alias: `ssh plex` (root, LXC 104 on Proxmox, IP: 192.168.0.205)
- Runs as native systemd service (not Docker), port 32400
- Plex Pass activated — hardware transcoding enabled
- **Hardware transcoding**: VAAPI enabled, Intel HD 630 GPU passed through (`/dev/dri/renderD128`)
- LXC resources: 2 cores, 4GB RAM (needs 4GB+ for transcoding with subtitles)
- GPU permissions: `renderD128` must be owned by `render` group (fix with `chgrp render /dev/dri/renderD128` after LXC restart)
- **Subtitles**: Embedded subs require video transcoding (burn-in) — needs Plex Pass for hardware acceleration

## Jellyfin
- SSH alias: `ssh jellyfin` (root, LXC 101 on Proxmox)
- Runs as native systemd service (not Docker)
- Media libraries: `/mnt/nas/media/movies` and `/mnt/nas/media/tv`
- Old Proxmox disk still mounted at `/mnt/media` (legacy)
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
- Intel HD 630 GPU shared between Jellyfin (LXC 101) and Plex (LXC 104) via VAAPI
- After any LXC restart, GPU permissions reset — fix with `chgrp render /dev/dri/renderD128`
- **Embedded subtitles** force video transcoding (burn-in) which is resource-intensive
  - Plex: requires Plex Pass for hardware-accelerated burn-in; needs 4GB+ RAM or transcoder gets OOM-killed
  - Jellyfin: extracts embedded subs as separate streams (avoids burn-in); use VAAPI not QSV (QSV crashes with subtitle burn-in)
- **External SRT subtitles** (from Bazarr) don't require transcoding — player renders them as overlay
- inotify file monitoring works over NFS but **not** over CIFS — this was the reason for switching to NFS

## Backups
- **Strategy**: Proxmox vzdump backs up all VMs/LXCs to Unraid NAS
- **NAS share**: `backups` on Unraid, NFS export at `192.168.0.101:/mnt/user/backups`
- **Proxmox storage**: `nas-backups` (NFS, content type: VZDump backup file)
- **Schedule**: Weekly, Sunday at 3:00 AM
- **Guests**: VM 100 (arrsuite), LXC 101 (Jellyfin), 102 (NPM), 103 (RustDesk), 104 (Plex)
- **Mode**: Snapshot (no downtime)
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
