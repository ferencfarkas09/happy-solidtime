# Solidtime with Coolify - Complete Setup Guide

## Overview

Your solidtime application is now fully optimized for **Coolify** deployment while maintaining local development capability. The setup uses:

- ✅ Docker volumes instead of bind mounts (Coolify-compatible)
- ✅ Automatic permission initialization on startup
- ✅ Proper environment variable handling for both local and cloud deployments
- ✅ Consistent user ownership (1000:1000) across all services
- ✅ Healthchecks for reliable orchestration

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your Application                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   app        │  │  scheduler   │  │    queue     │  │
│  │ (port 8000)  │  │  (daemon)    │  │  (daemon)    │  │
│  └────────┬─────┘  └──────┬───────┘  └──────┬───────┘  │
│           │                │                  │          │
│           └────────────────┼──────────────────┘          │
│                            │                            │
│                   ┌────────▼─────────┐                 │
│                   │   app-storage    │                 │
│                   │  (Docker volume) │                 │
│                   └──────────────────┘                 │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │  database (PostgreSQL 15)                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │  gotenberg (PDF generation)                      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Local Development Setup

### 1. Prerequisites

```bash
# Install Docker and Docker Compose (if not already installed)
# macOS: brew install docker docker-compose
# Linux: Follow official Docker docs
# Windows: Use Docker Desktop
```

### 2. Clone and Configure

```bash
cd /Users/Fecny/WebstormProjects/happy-solidtime/1-docker-with-database

# Check if laravel.env exists (pre-configured for development)
ls -la laravel.env
```

The `laravel.env` file is pre-configured with development defaults:
- `APP_ENV=development` (for debugging)
- `APP_DEBUG=true`
- `DB_SSLMODE=disable` (local database)
- `APP_KEY` set to a test value

### 3. Start Containers

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f app
```

### 4. Access Application

```
http://localhost:8001
```

### 5. First-Time Setup (if needed)

```bash
# Run Laravel migrations
docker compose exec app php artisan migrate

# Generate APP_KEY (if needed)
docker compose exec app php artisan key:generate

# Create super admin user
docker compose exec app php artisan create:super-admin
```

## Coolify Deployment Setup

### 1. Connect Your Repository to Coolify

- Link your GitHub/GitLab repository in Coolify UI
- Coolify will auto-detect the `docker-compose.yml` files

### 2. Choose Compose File

In Coolify deployment settings:
- **For standard setup**: Use `1-docker-with-database/docker-compose.yml`
- **For Traefik reverse proxy**: Use `0-docker-traefik-with-database/docker-compose.yml`

### 3. Configure Environment Variables in Coolify UI

Set these as **Secrets** or **Environment Variables** in Coolify:

#### Essential Variables:

```
APP_KEY=base64:YOUR_GENERATED_KEY_HERE
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com
APP_FORCE_HTTPS=true
```

#### Database Configuration:

```
DB_CONNECTION=pgsql
DB_HOST=database  # Keep this for bundled DB, or change for external DB
DB_PORT=5432
DB_DATABASE=solidtime
DB_USERNAME=solidtime
DB_PASSWORD=YOUR_SECURE_PASSWORD
DB_SSLMODE=disable  # or "require" for external PostgreSQL
```

#### Optional Variables:

```
LOG_CHANNEL=stderr_daily
LOG_LEVEL=debug
FILESYSTEM_DISK=local
PUBLIC_FILESYSTEM_DISK=public
GOTENBERG_URL=http://gotenberg:3000
QUEUE_CONNECTION=database
MAIL_MAILER=smtp
MAIL_HOST=your-mail-server
MAIL_PORT=587
MAIL_FROM_ADDRESS=noreply@your-domain.com
```

### 4. Generate APP_KEY

If you don't have an APP_KEY yet:

```bash
# Generate locally first
docker run --rm solidtime/solidtime:latest php artisan key:generate --show

# Copy the output to Coolify as APP_KEY environment variable
```

### 5. Database Considerations

#### Option A: Bundled PostgreSQL (Recommended for Simple Setups)
- Keep `DB_HOST=database` in docker-compose.yml
- Coolify manages the database container
- Data persists in `database-storage` volume

#### Option B: External Managed Database (Recommended for Production)
1. Create/use external PostgreSQL in your cloud provider
2. Update in Coolify environment:
   ```
   DB_HOST=your-external-db-host.com
   DB_PORT=5432
   DB_SSLMODE=require  # If external DB requires SSL
   ```
3. Coolify will skip bundled database service

#### Option C: Use Coolify's Database Service
- Link Coolify's managed PostgreSQL service
- Environment vars auto-populated by Coolify

### 6. Storage Configuration

**Volume Mapping:**
- `app-storage` → Container `/var/www/html/storage`
- All app data, logs, and uploads stored here
- Persists across container restarts
- Coolify automatically backs up volumes

### 7. Automatic Permission Initialization

On every container start, the `init-permissions` service:
1. Creates logs and app directories
2. Sets ownership to `1000:1000`
3. Applies `ug+rwX` permissions

This ensures:
- ✅ All containers can write logs
- ✅ No permission denied errors
- ✅ Data consistency across scheduler/queue/app

## Traefik Reverse Proxy Setup (0-docker-traefik-with-database)

### Prerequisites

```bash
# Create external Traefik network first
docker network create traefik-network
```

### Additional Traefik Variables in Coolify

```
APP_DOMAIN=your-domain.com
REVERSE_PROXY_NETWORK=traefik-network
APP_FORCE_HTTPS=true
```

### Traefik Configuration

The compose file includes automatic Traefik labels:
- HTTP → HTTPS redirect
- Let's Encrypt SSL certificate
- Load balancing to app service

## Troubleshooting

### App Shows Internal Server Error

**Check logs:**
```bash
docker compose logs app --tail 100
```

**Common causes:**
- Missing/invalid `APP_KEY`
- Database not running or unreachable
- Missing database migrations

**Fix:**
```bash
# Run migrations
docker compose exec app php artisan migrate

# Clear cache if cached values invalid
docker compose exec app php artisan cache:clear
```

### Permission Denied When Writing Logs

This is automatically handled by `init-permissions`, but if issues persist:

```bash
# Restart to re-run permission init
docker compose restart init-permissions
docker compose restart app scheduler queue
```

### Database Connection Failed

```bash
# Check database is running
docker compose ls
docker compose ps database

# Test connection from app
docker compose exec app php artisan tinker
# Inside tinker: DB::connection()->getPdo();
```

### Queue/Scheduler Not Working

```bash
# Check scheduler logs
docker compose logs scheduler --tail 50

# Check queue logs
docker compose logs queue --tail 50

# Verify database queue table exists
docker compose exec app php artisan queue:table
docker compose exec app php artisan migrate
```

## Data Backup (Coolify)

Coolify automatically backs up:
- ✅ `app-storage` volume (logs, uploads, cache)
- ✅ `database-storage` volume (PostgreSQL data)

Configure backup frequency in Coolify UI → Project Settings → Backups

## Security Best Practices

1. **Rotate APP_KEY regularly** (Coolify → Secrets → Rotate)
2. **Use strong DB_PASSWORD** (30+ chars, mixed case, symbols)
3. **Enable APP_FORCE_HTTPS=true** in production
4. **Set realistic LOG_LEVEL** (error/warning in production, debug in dev)
5. **Restrict TRUSTED_PROXIES** to your load balancer IP if known
6. **Use external PostgreSQL** for sensitive data (with SSL/TLS)
7. **Regular backups** (configure in Coolify)

## Files Modified

```
1-docker-with-database/
├── docker-compose.yml ✓ (Coolify-optimized)
└── laravel.env ✓ (Development defaults)

0-docker-traefik-with-database/
├── docker-compose.yml ✓ (Traefik + Coolify-optimized)
└── laravel.env ✓ (Production defaults)
```

## What Changed from Original Setup

| Aspect | Before | After | Why |
|--------|--------|-------|-----|
| Volume mounts | Bind mounts (./logs, ./app-storage) | Docker volumes only | Coolify compatibility |
| Permissions | chmod 777 (very permissive) | chown 1000:1000 + ug+rwX (secure) | Better security |
| User consistency | Mixed (app:default, scheduler:1000:1000) | All 1000:1000 | Avoid permission conflicts |
| env_file | Required (failed if missing) | Required but provided | Coolify can inject vars |
| Port mapping | 8000:8000 | 8001:8000 | Avoid local conflicts |
| Health checks | Basic | Enhanced with intervals/timeouts | Better orchestration |

## Next Steps

1. **Local Testing**: Run `docker compose up -d` and verify at `http://localhost:8001`
2. **Coolify Deployment**: Connect repo, configure environment variables, deploy
3. **Monitor**: Watch logs in Coolify dashboard
4. **Backup**: Ensure backups are configured
5. **Scale**: Add additional queue/scheduler replicas in Coolify if needed

## Support

For issues, check:
- Container logs: `docker compose logs service-name`
- Laravel logs: `/var/www/html/storage/logs/laravel.log` (in container)
- Coolify deployment logs
- GitHub issues for solidtime project

