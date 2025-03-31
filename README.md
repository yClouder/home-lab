# Ultimate Seedbox Setup

Over many years spent tinkering, tweaking, and fine-tuning my seedbox setup, I've constantly searched for a definitive guide to fully automate my media workflow—but I've only ever found fragmented snippets scattered across Reddit threads, GitHub repositories, and countless Google searches. It's frustrating for anyone, beginner or veteran, to piece this puzzle together seamlessly. There’s simply too much conflicting information, incomplete instructions, and cryptic technical jargon that leave many users stuck and overwhelmed. With that frustration in mind, I've meticulously gathered and distilled the knowledge from my trials (and plenty of errors!), alongside valuable nuggets of wisdom gleaned from various online communities, to craft the ultimate step-by-step guide that anyone can follow.

My goal? To help you automate your seedbox effortlessly, reliably, and—crucially—in a SECURE manner! Whether you're just getting started or have been tweaking setups for years, this guide will streamline your media management process from start to finish.

Here's a quick glance at the Docker containers we'll use, complete with clear explanations of what each one does:

- 🔒 Gluetun: A sleek, all-in-one VPN client supporting multiple providers—your digital Swiss Army knife, ensuring your privacy remains rock-solid while torrenting and streaming.
- 🌐 NginX Proxy Manager: A Docker-based tool that effortlessly handles secure web forwarding, including SSL certificates, without you needing deep Nginx or Letsencrypt knowledge. Perfect for securely accessing your apps from anywhere.
- ⬇️ qBittorrent: The reliable, open-source alternative to µTorrent, built on Qt and libtorrent-rasterbar, providing a lightweight yet robust solution for downloading torrents with ease.
- 🔄 qBittorrent Port Forwarder: Automatically syncs qBittorrent's ports through Gluetun, ensuring maximum connectivity and optimal speeds without manual port configuration headaches.
- 🎬 Radarr: Automates movie downloads and management—think CouchPotato, but smarter, slicker, and fully integrated into your workflow, making movie management a breeze.
- 📺 Sonarr: Your personal TV assistant, automatically fetching, sorting, renaming, and even upgrading episodes. It monitors RSS feeds and ensures your TV shows are always ready and waiting.
- 🔍 Prowlarr: Centralized management for torrent and Usenet indexers—effortlessly integrated across Sonarr, Radarr, Lidarr, and Readarr, eliminating the hassle of configuring indexers individually for each app.
- 📦 Unpackerr: Watches completed downloads, swiftly unpacking files so they're instantly ready for import by your media apps, removing yet another manual step from your workflow.
- 📝 Overseerr: Streamlined media request management, neatly integrated with Sonarr, Radarr, and Plex. Overseerr handles user requests smoothly, simplifying the media approval and addition process.
- 📡 Plex Media Server: Organizes and streams your media to all your devices—simple, intuitive, and powerful. With Plex, your entire media collection becomes accessible anytime, anywhere, beautifully organized, and instantly available.

By the end of this guide, you'll have a powerful, fully-automated media system that's secure, efficient, and hassle-free.

Check out the full guide here: https://passthebits.com/

## Quick Start
Carefully read the entire compose file before deploying. Comments are included with details and additional supported variables. Confirm that all uncommented service variables and volumes are correctly configured before deploying. The compose file is available on GitHub.
```
git clone https://github.com/pvd-nerd/docker-arr-suite $HOME/media_stack
cd $HOME/media_stack
chmod +x media.sh

# Pull all container images and set permissions on your NAS. The script prompts for NAS IP and volume mount.
./media.sh init

# Start stack services. Initial startup may take time. If startup fails, consider increasing the `start_period` in the compose file.
./media.sh up
```

Some containers won't start until environment variables are set. Allow them to restart continuously initially.
