# Agent Configuration for Proxmox Home Lab Infrastructure

## Repository Overview

This repository contains a Docker-based home lab setup designed for Proxmox virtualization. It implements a distributed architecture with services separated by function across VMs and LXC containers for optimal resource utilization and management.

## Architecture

```
Internet → Nginx Proxy Manager LXC (80/443) → VM1 (Media Management + BitTorrent)
                                             → VM2 (Other services)
                                             → Jellyfin LXC (Media Server)
                                             → Additional LXCs
```

## Key Components

### Core Services (This Repository)
- **qBittorrent**: Torrent client with web interface (port 8088)
- **Radarr**: Movie management (port 7878)
- **Sonarr**: TV show management (port 8989)
- **Prowlarr**: Indexer management (port 9696)
- **Watchtower**: Container updates
- **FlareSolverr**: Cloudflare challenge solver (port 8191)

### External Dependencies
- **Nginx Proxy Manager**: Reverse proxy with SSL (separate LXC)
- **Jellyfin**: Media server (separate LXC)
- **NFS Storage**: Centralized storage mounted at `/mnt/media`

## File Structure

```
├── docker-compose.yml          # Main compose file
├── arr-compose.yml             # Radarr, Sonarr, Prowlarr services
├── bittorrent-compose.yml      # qBittorrent services
├── flaresolverr-compose.yml    # FlareSolverr for Cloudflare protection
├── env/                        # Environment configuration files
├── secrets/                    # Docker secrets (API keys, passwords)
├── README.md                   # Project documentation
└── CLAUDE.md                   # Detailed technical documentation
```

## Storage Structure

The NFS volume should be mounted to `/mnt/media` with this structure:

```
/mnt/media/
├── data/                    # Media and download directories
│   ├── torrents/            # qBittorrent active downloads
│   │   ├── incomplete/      # Downloads in progress
│   │   └── complete/        # Completed downloads
│   ├── movies/              # Radarr managed movie library
│   └── tv/                  # Sonarr managed TV show library
└── docker_data/             # Application configuration and databases
    ├── sonarr/              # Sonarr database and settings
    ├── radarr/              # Radarr database and settings
    ├── prowlarr/            # Indexer configurations
    ├── bittorrent/          # qBittorrent settings and state
    └── flaresolverr/        # FlareSolverr instances and cache
```

## Port Configuration

- **8088**: qBittorrent Web UI
- **8989**: Sonarr Web UI  
- **7878**: Radarr Web UI
- **9696**: Prowlarr Web UI
- **8191**: FlareSolverr API

## Key Concepts for AI Agents

### 1. Service Dependencies
- All *arr services depend on proper storage mounting
- Services use health checks for proper startup order
- FlareSolverr should start before Prowlarr for indexer access

### 2. Network Architecture
- No local reverse proxy in this VM
- External Nginx Proxy Manager handles SSL and routing
- Direct internet access for downloads (no VPN)

### 3. Storage Management
- Uses NFS bind mounts for persistent data
- Centralized storage across all services
- Directory permissions must be set correctly

### 4. Security Model
- Docker secrets for sensitive configuration
- Direct internet access for downloads
- No direct internet exposure (proxied through Nginx)
- FlareSolverr handles Cloudflare protection

## Common Tasks for AI Agents

### Setup and Deployment
1. **Environment Configuration**: Set up files in `env/` directory
2. **Secrets Management**: Configure Docker secrets in `secrets/` directory
3. **Storage Preparation**: Create required directory structure on NFS mount
4. **Service Deployment**: Use `docker compose up -d` to start services

### Troubleshooting
1. **Indexer Issues**: Check FlareSolverr logs and Prowlarr configuration
2. **Storage Problems**: Verify NFS mount and directory permissions
3. **Service Failures**: Check health checks and dependency order
4. **Network Issues**: Verify port exposure and proxy configuration

### Scaling and Maintenance
1. **Adding Services**: Create new compose files and expose ports
2. **Updates**: Watchtower handles automatic updates
3. **Monitoring**: Check service health and logs
4. **Backup**: Backup `docker_data` directories for configuration

## Configuration Files

### Environment Files (`env/`)
- Service-specific environment variables
- Network and storage configuration
- API keys and endpoints

### Docker Secrets (`secrets/`)
- Passwords and API keys
- Sensitive configuration data
- Mounted into containers securely

### Compose Files
- **Main**: Orchestrates all services
- **ARR**: Manages Radarr, Sonarr, Prowlarr
- **BitTorrent**: Handles torrent client
- **FlareSolverr**: Cloudflare challenge solver

## Best Practices

1. **Always check service dependencies before starting**
2. **Verify NFS mount and permissions before deployment**
3. **Use Docker secrets for sensitive data**
4. **Monitor health checks for proper service startup**
5. **Keep services updated through Watchtower**
6. **Maintain proper directory structure on storage**
7. **Ensure FlareSolverr is running before adding protected indexers**

## Common Commands

```bash
# Start all services
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs [service-name]

# Pull latest images
docker compose pull

# Stop all services
docker compose down

# Rebuild and restart
docker compose up -d --build
```

## Error Handling

- **Indexer Access Issues**: Check FlareSolverr status and Prowlarr configuration
- **Storage Mount Failures**: Verify NFS server and network connectivity
- **Service Startup Failures**: Check health checks and dependency order
- **Port Conflicts**: Ensure ports are not used by other services
- **Cloudflare Challenges**: Verify FlareSolverr is running and accessible

This agent configuration provides comprehensive understanding of the repository structure, architecture, and operational requirements for AI agents working with this Proxmox home lab infrastructure.
