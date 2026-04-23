#!/bin/bash

# Solidtime Local Development Quick Start
# Run this script to start the application with all services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/1-docker-with-database"

echo "🚀 Starting Solidtime with Docker Compose..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker daemon is not running. Please start Docker first."
    exit 1
fi

cd "$COMPOSE_DIR"

# Check if laravel.env exists
if [ ! -f "laravel.env" ]; then
    echo "⚠️  laravel.env not found. Creating from defaults..."
    cp laravel.env.example laravel.env || touch laravel.env
fi

# Start containers
echo "📦 Starting containers..."
docker compose up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check database connection
echo ""
echo "🔗 Testing database connection..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if docker compose exec -T database pg_isready -U solidtime -d solidtime > /dev/null 2>&1; then
        echo "✅ Database is ready"
        break
    fi
    attempt=$((attempt + 1))
    echo "  Attempt $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Database failed to start. Check logs with: docker compose logs database"
    exit 1
fi

# Show status
echo ""
echo "✅ All services started successfully!"
echo ""
echo "📊 Service Status:"
docker compose ps
echo ""
echo "🌐 Application URL: http://localhost:8001"
echo ""
echo "📝 Useful Commands:"
echo "   View logs:        docker compose logs -f app"
echo "   Run migrations:   docker compose exec app php artisan migrate"
echo "   Create admin:     docker compose exec app php artisan create:super-admin"
echo "   Laravel tinker:   docker compose exec app php artisan tinker"
echo "   Stop services:    docker compose down"
echo "   Remove all data:  docker compose down -v"
echo ""

