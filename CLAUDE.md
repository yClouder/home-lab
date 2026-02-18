# Home Lab Project

## Overview
This is a Docker-based home lab setup with multiple services organized in separate compose files. My objective is using this repo for controlling my applications running on my Proxmox server.

## Architecture
```
Internet → Nginx Proxy Manager LXC (80/443) → miniPC (Arr + BitTorrent services)
                                             → Jellyfin LXC
                                             → Other LXCs
```

## Project Structure
- `docker-compose.yml` - Main compose file (watchtower + includes)
- `arr-compose.yml` - Arr stack (Radarr, Sonarr, Prowlarr)
- `bittorrent-compose.yml` - qBittorrent
- `flaresolverr-compose.yml` - FlareSolverr (CAPTCHA solver for Prowlarr)
- `secrets/` - Docker secrets directory
- `env/` - Environment files

## Services
- **qBittorrent**: Torrent client (port 8088)
- **Sonarr**: TV show management (port 8989)
- **Radarr**: Movie management (port 7878)
- **Prowlarr**: Indexer manager (port 9696)
- **FlareSolverr**: CAPTCHA solver (port 8191)
- **Watchtower**: Auto-updates

## Ports Exposed
- 8088: qBittorrent web UI
- 8989: Sonarr web UI
- 7878: Radarr web UI
- 9696: Prowlarr web UI
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
  ├── bittorrent/            # qBittorrent settings
  └── flaresolverr/          # FlareSolverr cache
  ```

## Notes
- Gluetun/VPN removed — qBittorrent runs without VPN currently
- Unpackerr disabled due to API key reading issue
- NAS CIFS share pre-mounted on host to avoid Docker NFS driver complexity
- No local reverse proxy - handled by external Nginx Proxy Manager LXC
- Secrets are stored in Docker secrets format
