#!/bin/bash
# Script to fix Docker volume permissions for solidtime

# Fix permissions for 1-docker-with-database
echo "Fixing permissions for 1-docker-with-database..."
chmod -R 777 ./1-docker-with-database/logs ./1-docker-with-database/app-storage

# Fix permissions for 0-docker-traefik-with-database
echo "Fixing permissions for 0-docker-traefik-with-database..."
chmod -R 777 ./0-docker-traefik-with-database/logs ./0-docker-traefik-with-database/app-storage

echo "✓ Permissions fixed! Docker containers should now be able to write logs."
echo ""
echo "What was fixed:"
echo "- logs/ directories are now world-writable (777)"
echo "- app-storage/ directories are now world-writable (777)"
echo ""
echo "This allows Docker container processes (running as user 1000:1000)"
echo "to write logs and storage files without permission errors."

