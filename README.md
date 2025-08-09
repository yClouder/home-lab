# Proxmox Home Lab Infrastructure

A Docker-based home lab setup designed for Proxmox virtualization, with distributed services across VMs and LXC containers for optimal resource utilization and management.

## Architecture Overview

This setup uses a distributed architecture with services separated by function:

```
Internet → Nginx Proxy Manager LXC (80/443) → VM1 (Media Management + BitTorrent)
                                             → VM2 (Other services)
                                             → Jellyfin LXC (Media Server)
                                             → Additional LXCs
```

## Key Benefits

- **Centralized Reverse Proxy**: Single Nginx Proxy Manager LXC handles SSL and routing for all services
- **Resource Optimization**: Services distributed across VMs/LXCs based on resource needs
- **Scalability**: Easy to add new VMs/LXCs without duplicate infrastructure
- **Security**: VPN-secured torrenting through Gluetun
- **Storage**: Centralized NFS storage for all persistent data

## Services Overview

### VM Services (This Repository)
- 🔒 **Gluetun**: VPN client ensuring secure torrenting with multiple provider support
- ⬇️ **qBittorrent**: Reliable torrent client with web interface (port 8088)
- 🔄 **Port Forwarder**: Automatic port forwarding sync for optimal torrent speeds
- 🎬 **Radarr**: Automated movie management and downloading (port 7878)  
- 📺 **Sonarr**: TV show monitoring and management (port 8989)
- 🔍 **Prowlarr**: Centralized indexer management for all *arr apps (port 9696)
- 📦 **Unpackerr**: Automatic archive extraction for completed downloads
- 🚢 **Watchtower**: Automatic Docker container updates

### External Services (Separate LXCs)
- 🌐 **Nginx Proxy Manager**: Reverse proxy with SSL certificate management
- 📡 **Jellyfin**: Open-source media server for streaming

## Quick Start

1. **Clone and prepare**:
```bash
git clone <your-repo> /home/user/home-lab
cd /home/user/home-lab
```

2. **Configure environment files**:
   - Set up files in the `env/` directory for each service
   - Configure Docker secrets in `secrets/` directory
   - Update `MEDIA_PATH` in `env/nfs.env` if your mount differs from `/mnt/media`

3. **Prepare storage structure**:
   - Mount your NFS share to `/mnt/media` in the VM
   - Create required directory structure (see below)

4. **Create directory structure**:
```bash
# Create required directories on your NFS mount
sudo mkdir -p /mnt/media/data/{torrents/{incomplete,complete},movies,tv}
sudo mkdir -p /mnt/media/docker_data/{gluetun,sonarr,radarr,prowlarr,unpackerr,bittorrent}
sudo chown -R $USER:$USER /mnt/media
```

5. **Deploy services**:
```bash
# Pull all images
docker compose pull

# Start all VM services
docker compose up -d
```

## Port Mapping

The VM exposes these ports for Nginx Proxy Manager to proxy:
- **8088**: qBittorrent Web UI
- **8989**: Sonarr Web UI  
- **7878**: Radarr Web UI
- **9696**: Prowlarr Web UI

## File Structure

```
├── docker-compose.yml          # Main compose file
├── arr-compose.yml             # Radarr, Sonarr, Prowlarr services
├── bittorrent-compose.yml      # qBittorrent and VPN services
├── jellyfin-compose.yml        # Jellyfin (for separate LXC)
├── env/                        # Environment configuration files
├── secrets/                    # Docker secrets (API keys, passwords)
└── CLAUDE.md                   # Detailed project documentation
```

## Storage Structure

The NFS volume should be mounted to `/mnt/media` in the VM with this directory structure:

```
/mnt/media/
├── data/                    # Media and download directories
│   ├── torrents/            # qBittorrent active downloads
│   │   ├── incomplete/      # Downloads in progress
│   │   └── complete/        # Completed downloads
│   ├── movies/              # Radarr managed movie library
│   └── tv/                  # Sonarr managed TV show library
└── docker_data/             # Application configuration and databases
    ├── gluetun/             # VPN configuration and logs
    ├── sonarr/              # Sonarr database and settings
    ├── radarr/              # Radarr database and settings
    ├── prowlarr/            # Indexer configurations
    ├── unpackerr/           # Archive extraction settings
    └── bittorrent/          # qBittorrent settings and state
```

## Configuration Notes

- **Storage**: NFS volume pre-mounted to `/mnt/media` using bind mounts
- **VPN**: All torrent traffic routed through Gluetun VPN container
- **Networking**: No local reverse proxy - handled by external Nginx Proxy Manager
- **Security**: Secrets managed through Docker secrets for sensitive data
- **Updates**: Watchtower automatically keeps containers updated
- **Startup**: Health checks ensure proper service dependency order

## Scaling

To add more services:
1. Create additional VMs/LXCs as needed
2. Add service configuration to appropriate compose files
3. Expose required ports for Nginx Proxy Manager
4. Configure proxy hosts in Nginx Proxy Manager

This architecture allows for easy horizontal scaling while maintaining centralized management.