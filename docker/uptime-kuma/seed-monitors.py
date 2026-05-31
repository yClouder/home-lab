#!/usr/bin/env python3
"""
Seed Uptime Kuma with the homelab's initial monitor set.

Idempotent: skips any monitor whose name already exists.

Usage (from inside the kuma LXC):
    KUMA_URL=http://localhost:3001 \
    KUMA_USER=<admin> \
    KUMA_PASS=<pass> \
    /opt/uptime-kuma-tools/bin/python seed-monitors.py

Re-run after disaster recovery to recreate the baseline monitor set.
"""

import os
import sys
from uptime_kuma_api import UptimeKumaApi, MonitorType


# Internal LAN targets — referenced by IP/hostname so we monitor the thing
# itself, not the proxy chain in front of it.
PROXMOX_M910Q = "https://192.168.0.200:8006"
PROXMOX_M70Q  = "https://192.168.0.220:8006"
NAS_HOST      = "192.168.0.101"
MINECRAFT_IP  = "192.168.0.210"


MONITORS = [
    # --- Public *.yclouder.com (covers DNS + NPM + upstream service) ---
    {"type": MonitorType.HTTP, "name": "Public: proxmox.yclouder.com",  "url": "https://proxmox.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: nginx.yclouder.com",    "url": "https://nginx.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: nas.yclouder.com",      "url": "https://nas.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: jellyfin.yclouder.com", "url": "https://jellyfin.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: torrent.yclouder.com",  "url": "https://torrent.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: prowlarr.yclouder.com", "url": "https://prowlarr.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: sonarr.yclouder.com",   "url": "https://sonarr.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: radarr.yclouder.com",   "url": "https://radarr.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: bazarr.yclouder.com",   "url": "https://bazarr.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: minecraft.yclouder.com", "url": "https://minecraft.yclouder.com"},
    {"type": MonitorType.HTTP, "name": "Public: kuma.yclouder.com",     "url": "https://kuma.yclouder.com"},

    # --- Proxmox hosts (direct, ignore self-signed cert) ---
    {"type": MonitorType.HTTP, "name": "Proxmox m910q (direct)", "url": PROXMOX_M910Q, "ignoreTls": True},
    {"type": MonitorType.HTTP, "name": "Proxmox m70q (direct)",  "url": PROXMOX_M70Q,  "ignoreTls": True},

    # --- Unraid NAS ---
    {"type": MonitorType.HTTP, "name": "NAS Unraid web UI",   "url": f"http://{NAS_HOST}"},
    {"type": MonitorType.PORT, "name": "NAS NFS (TCP 2049)", "hostname": NAS_HOST, "port": 2049},

    # --- Minecraft game port (m70q) ---
    # Server runs on 25578, not the vanilla 25565. Crafty Controller web UI
    # is on 8443 and is what minecraft.yclouder.com proxies to.
    {"type": MonitorType.PORT, "name": "Minecraft (TCP 25578)", "hostname": MINECRAFT_IP, "port": 25578},
    {"type": MonitorType.PORT, "name": "Crafty Controller (TCP 8443)", "hostname": MINECRAFT_IP, "port": 8443},

    # --- Internet egress ---
    {"type": MonitorType.PING, "name": "Internet: 1.1.1.1", "hostname": "1.1.1.1"},
    {"type": MonitorType.PING, "name": "Internet: 8.8.8.8", "hostname": "8.8.8.8"},
]

# Defaults applied to every monitor unless overridden in the dict above.
DEFAULTS = {
    "interval": 60,        # seconds between checks
    "retryInterval": 30,
    "maxretries": 2,
    "accepted_statuscodes": ["200-299", "300-399"],
}


def main() -> int:
    url  = os.environ.get("KUMA_URL", "http://localhost:3001")
    user = os.environ["KUMA_USER"]
    pw   = os.environ["KUMA_PASS"]

    print(f"Connecting to {url} as {user} ...")
    api = UptimeKumaApi(url)
    api.login(user, pw)
    try:
        existing = {m["name"] for m in api.get_monitors()}
        print(f"Existing monitors: {len(existing)}")

        created = skipped = 0
        for m in MONITORS:
            if m["name"] in existing:
                print(f"  skip  {m['name']}")
                skipped += 1
                continue
            payload = {**DEFAULTS, **m}
            # accepted_statuscodes only valid for HTTP-family monitors
            if payload["type"] not in (MonitorType.HTTP, MonitorType.KEYWORD):
                payload.pop("accepted_statuscodes", None)
            r = api.add_monitor(**payload)
            print(f"  add   {m['name']}  (id={r.get('monitorID')})")
            created += 1

        print(f"\nDone. created={created} skipped={skipped} total={len(MONITORS)}")
    finally:
        api.disconnect()
    return 0


if __name__ == "__main__":
    sys.exit(main())
