# Proxmox Home Lab Infrastructure

A Docker-based home lab setup designed for Proxmox virtualization, with distributed services across a miniPC and LXC containers. Media is stored on an Unraid NAS.

## Architecture Overview

```
Internet → Nginx Proxy Manager LXC (80/443) → miniPC (Media Management + BitTorrent)
                                             → Jellyfin LXC (Media Server)
                                             → Other LXCs

Unraid NAS (192.168.0.101) ← NFS → miniPC (/mnt/nas)
                            ← NFS → Proxmox → bind mount → Jellyfin LXC (/mnt/nas/media)
                                             → bind mount → Plex LXC (/mnt/nas/media)
```

## Services

### miniPC (This Repository)
- **qBittorrent**: Torrent client with web interface (port 8088)
- **Radarr**: Automated movie management (port 7878)
- **Sonarr**: TV show monitoring and management (port 8989)
- **Prowlarr**: Centralized indexer management (port 9696)
- **Bazarr**: Subtitle management (port 6767)
- **FlareSolverr**: Cloudflare challenge solver for protected indexers (port 8191)
- **Watchtower**: Automatic Docker container updates

### External Services (Separate LXCs)
- **Nginx Proxy Manager**: Reverse proxy with SSL certificate management (LXC 102)
- **Jellyfin**: Open-source media server with VAAPI hardware transcoding (LXC 101)
- **Plex**: Media server with Plex Pass hardware transcoding (LXC 104)

## Quick Start

1. **Clone and prepare**:
```bash
git clone <your-repo> ~/repos/home-lab
cd ~/repos/home-lab
```

2. **Configure environment files**:
   - Set up files in the `env/` directory for each service
   - Configure Docker secrets in `secrets/` directory

3. **Mount the NAS** (NFS):
```bash
sudo apt install nfs-common
sudo mkdir -p /mnt/nas
echo '192.168.0.101:/mnt/user/media /mnt/nas nfs defaults,_netdev,soft,timeo=100,rsize=131072,wsize=131072 0 0' | sudo tee -a /etc/fstab
sudo mount -a
```

4. **Create directory structure**:
```bash
# NAS media directories
mkdir -p /mnt/nas/media/{torrents/{incomplete,complete},movies,tv}

# Local app config directories
sudo mkdir -p /opt/docker_data/{sonarr,radarr,prowlarr,bazarr,bittorrent,flaresolverr}
sudo chown -R $USER:$USER /opt/docker_data
```

5. **Deploy services**:
```bash
docker compose pull
docker compose up -d
```

## Port Mapping

| Port | Service |
|------|---------|
| 8088 | qBittorrent Web UI |
| 8989 | Sonarr Web UI |
| 7878 | Radarr Web UI |
| 9696 | Prowlarr Web UI |
| 6767 | Bazarr Web UI |
| 8191 | FlareSolverr API |

## File Structure

```
├── docker-compose.yml          # Main compose file (watchtower + includes)
├── arr-compose.yml             # Radarr, Sonarr, Prowlarr, Bazarr
├── bittorrent-compose.yml      # qBittorrent
├── flaresolverr-compose.yml    # FlareSolverr
├── env/                        # Environment configuration files
├── secrets/                    # Docker secrets (API keys, passwords)
└── CLAUDE.md                   # Detailed project documentation
```

## Storage

Storage is split between the NAS (media data) and local disk (app configs).

### NAS (`/mnt/nas/media/` via NFS)
```
/mnt/nas/media/
├── torrents/              # qBittorrent downloads
├── movies/                # Radarr managed movie library
└── tv/                    # Sonarr managed TV show library
```

### Local (`/opt/docker_data/`)
```
/opt/docker_data/
├── sonarr/                # Sonarr database and settings
├── radarr/                # Radarr database and settings
├── prowlarr/              # Indexer configurations
├── bazarr/                # Bazarr database
├── bittorrent/            # qBittorrent settings
└── flaresolverr/          # FlareSolverr cache
```

All containers mount the NAS media root at `/media/` inside the container:
- qBittorrent saves to `/media/torrents/`
- Sonarr root folder: `/media/tv/`
- Radarr root folder: `/media/movies/`

## Service Connections

```
Prowlarr (indexers) → syncs to → Sonarr + Radarr
FlareSolverr → used by → Prowlarr (via tag, for Cloudflare-protected indexers)
qBittorrent ← download client for ← Sonarr + Radarr
Jellyfin ← reads media from ← NAS (/mnt/nas/media/movies, /mnt/nas/media/tv)
Plex    ← reads media from ← NAS (/mnt/nas/media/movies, /mnt/nas/media/tv)
```

## Configuration Notes

- **Storage**: NAS NFS share pre-mounted on host, app configs on local disk for performance
- **Networking**: No local reverse proxy — handled by external Nginx Proxy Manager LXC
- **Security**: Secrets managed through Docker secrets
- **Updates**: Watchtower automatically keeps containers updated
- **Startup**: Health checks ensure proper service dependency order
- **VPN**: Gluetun/VPN currently disabled — qBittorrent runs without VPN
- **Hardware transcoding**: Intel HD 630 GPU (VAAPI) shared between Jellyfin and Plex LXCs via `/dev/dri/renderD128`
