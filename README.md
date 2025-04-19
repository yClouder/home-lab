# Automated Media Management Setup

After years of trial, error, and endless Reddit dives, I built the guide I wish I had from the start—a clear, step-by-step walkthrough to fully automate your seedbox in a secure, reliable way. Whether you're new or a seasoned tweaker, this will streamline your media setup from start to finish.

Below is a quick overview of the Docker containers used and what each one does.

- 🔒 Gluetun: A sleek, all-in-one VPN client supporting multiple providers—your digital Swiss Army knife, ensuring your privacy remains rock-solid while torrenting and streaming.
- 🌐 Traefik: A modern, lightweight reverse proxy and load balancer—your traffic’s front door with smart routing, automatic HTTPS via Let's Encrypt, and seamless Docker integration. Simple to use, powerful to scale.
- ⬇️ qBittorrent: The reliable, open-source alternative to µTorrent, built on Qt and libtorrent-rasterbar, providing a lightweight yet robust solution for downloading torrents with ease.
- 🔄 qBittorrent Port Forwarder: Automatically syncs qBittorrent's ports through Gluetun, ensuring maximum connectivity and optimal speeds without manual port configuration headaches.
- 🎬 Radarr: Automates movie downloads and management—think CouchPotato, but smarter, slicker, and fully integrated into your workflow, making movie management a breeze.
- 📺 Sonarr: Your personal TV assistant, automatically fetching, sorting, renaming, and even upgrading episodes. It monitors RSS feeds and ensures your TV shows are always ready and waiting.
- 🔍 Prowlarr: Centralized management for torrent and Usenet indexers—effortlessly integrated across Sonarr, Radarr, Lidarr, and Readarr, eliminating the hassle of configuring indexers individually for each app.
- 📦 Unpackerr: Watches completed downloads, swiftly unpacking files so they're instantly ready for import by your media apps, removing yet another manual step from your workflow.
- 📝 Overseerr & Jellyseerr: Easy, user-friendly media request tools for Sonarr, Radarr, Plex, and Jellyfin—making content requests and approvals a breeze.
- 📡 Plex & Jellyfin: Stream and organize your media anywhere. Plex offers sleek, remote access; Jellyfin is open-source and privacy-focused—both keep your library beautifully managed.
- 🚢 Watchtower: Automatically keeps your Docker containers up to date with the latest images—set it and forget it for a smoother, more secure stack.

By the end of this guide, you'll have a powerful, fully-automated media system that's secure, efficient, and hassle-free.

Check out the full guide here: https://passthebits.com/

## Quick Start
Carefully read the entire compose file before deploying. Comments are included with details and additional supported variables. Confirm that all uncommented service variables and volumes are correctly configured before deploying. The compose file is available on GitHub.
```
git clone https://github.com/pvd-nerd/docker-arr-suite $HOME/media_stack
cd $HOME/media_stack
chmod +x media.sh

# Pull all container images before launch.
sudo docker compose pull

# Start stack services. Initial startup may take a while.
# If startup fails, consider increasing the `start_period` in the compose file.
sudo docker compose up -d
```

Some containers won't start until environment variables are set. Allow them to restart continuously initially.