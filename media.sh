#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {up|down|upgrade|init}"
    exit 1
fi

case "$1" in
    up)
        sudo docker compose up -d 
        ;;
    down)
        sudo docker compose down -v
        ;;
    upgrade)
        sudo docker compose pull
        sudo docker compose down -v
        sudo docker compose up -d
        ;;
    init)
        read -p "Enter the NFS server IP: " NFS_SERVER_IP
        read -p "Enter the NFS volume (e.g., /volume1/media): " NFS_VOLUME
        sudo mkdir -p /tmp/mount
        sudo mount -t nfs "$NFS_SERVER_IP:$NFS_VOLUME" /tmp/mount/
        sudo chown -R 1000:1000 /tmp/mount/movies
        sudo chmod -R 764 /tmp/mount/movies
        sudo chown -R 1000:1000 /tmp/mount/shows
        sudo chmod -R 764 /tmp/mount/movies
        sudo umount /tmp/mount
        sudo rm -rf /tmp/mount
        sudo docker compose pull
        ;;
    *)
        echo "Invalid parameter: $1"
        echo "Usage: $0 {up|down|upgrade|init}"
        exit 1
        ;;
esac
