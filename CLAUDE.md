# Home Lab Project

## Overview
This is a Docker-based home lab setup with multiple services organized in separate compose files. My objective is using this repo for controlling my applications running on my Proxmox server.

## Architecture
```
Internet → Nginx Proxy Manager LXC (80/443) → VM1 (Arr + BitTorrent services)
                                             → VM2 (other services)
                                             → Jellyfin LXC
                                             → Other LXCs
```

## Project Structure
- `docker-compose.yml` - Main compose file (VM services only)
- `arr-compose.yml` - Arr stack (Radarr, Sonarr, Prowlarr) - Runs on VM
- `bittorrent-compose.yml` - qBittorrent/VPN services - Runs on VM
- `jellyfin-compose.yml` - Jellyfin media server - Runs on separate LXC
- `plex-compose.yml` - Plex media server - Not used
- `secrets/` - Docker secrets directory
- `env/` - Environment files

## Services on VM
- **Gluetun**: VPN container for secure torrenting
- **qBittorrent**: Torrent client (port 8088)
- **Sonarr**: TV show management (port 8989)
- **Radarr**: Movie management (port 7878)
- **Prowlarr**: Indexer manager (port 9696)
- **Unpackerr**: Archive extraction
- **Watchtower**: Auto-updates

## External Services
- **Nginx Proxy Manager**: Reverse proxy with SSL (runs on separate LXC)
- **Jellyfin**: Media server (runs on separate LXC)

## Ports Exposed
The VM exposes these ports for the external Nginx Proxy Manager LXC:
- 8088: qBittorrent web UI
- 8989: Sonarr web UI
- 7878: Radarr web UI  
- 9696: Prowlarr web UI

## Commands
- Use `docker-compose up -d` to start all VM services
- Check individual compose files for specific service management

## Storage Configuration
- **NFS Mount**: Proxmox NFS volume mounted locally to `/mnt/media` in VM
- **Docker Volumes**: Use bind mounts to `/mnt/media` subdirectories
- **Directory Structure**:
  ```
  /mnt/media/
  ├── data/
  │   ├── torrents/          # qBittorrent downloads
  │   ├── movies/            # Radarr managed movies
  │   └── tv/                # Sonarr managed TV shows
  └── docker_data/
      ├── gluetun/           # VPN config
      ├── sonarr/            # Sonarr database
      ├── radarr/            # Radarr database  
      ├── prowlarr/          # Indexer configs
      ├── unpackerr/         # Extraction configs
      └── bittorrent/        # qBittorrent settings
  ```

## Notes
- All torrent traffic goes through VPN (Gluetun)
- NFS volume pre-mounted to avoid Docker NFS driver complexity
- No local reverse proxy - handled by external Nginx Proxy Manager LXC
- Secrets are stored in Docker secrets format
- Environment variable `MEDIA_PATH=/mnt/media` configures all bind mounts