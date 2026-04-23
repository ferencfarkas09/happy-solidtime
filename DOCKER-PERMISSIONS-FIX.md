# Docker Permission Issues - Solution

## Problem
The solidtime Docker containers were failing with permission denied errors when trying to write logs:
```
The stream or file "/var/www/html/storage/logs/laravel.log" could not be opened in append mode: Failed to open stream: Permission denied
```

## Root Cause
The mounted volumes (`logs/` and `app-storage/`) on the host machine had restrictive permissions (`755`), but the Docker container processes were running as users that didn't have write access to these directories. Specifically:
- **Container users**: `1000:1000` (scheduler, queue) and the default app user
- **Directory permissions**: `drwxr-xr-x` (755) - only owner could write

## Automatic Solution ✅
**The permission fixes are now automatically applied when you run `docker-compose`!**

The `docker-compose.yml` files now include an `init-permissions` service that:
1. Runs before any other containers start
2. Automatically sets permissions to `777` on `logs/` and `app-storage/` directories
3. Exits successfully, allowing other services to proceed

No manual action is needed. Simply run:
```bash
docker-compose up -d
```

And the permissions will be fixed automatically on first run.

## Manual Solution (Alternative)
If you prefer to manually fix permissions:

```bash
chmod -R 777 ./1-docker-with-database/logs
chmod -R 777 ./1-docker-with-database/app-storage
chmod -R 777 ./0-docker-traefik-with-database/logs
chmod -R 777 ./0-docker-traefik-with-database/app-storage
```

Or run the provided script:
```bash
./fix-permissions.sh
```

## How It Works
1. **init-permissions service**: A lightweight Alpine Linux container that runs chmod commands
2. **Dependency chain**: All other services depend on `init-permissions`, so they wait for it to complete
3. **Permissions `777`**: Means Owner, Group, and Others all have read, write, and execute permissions
4. **Result**: The Docker container processes can now write files regardless of their user ID

## Architecture
The updated `docker-compose.yml` now includes:
```yaml
init-permissions:
  image: alpine:latest
  volumes:
    - "./logs:/storage/logs"
    - "./app-storage:/storage/app"
  command: sh -c "chmod -R 777 /storage/logs /storage/app && echo 'Permissions fixed!'"
  networks:
    - internal
```

All other services have `depends_on: [database, init-permissions]` ensuring the permissions are set before they start.

## Alternative Solutions
If you want even more restrictive permissions, you could:
1. **Change docker-compose.yml** to run all services as your local user
2. **Use Docker user namespace remapping** to map container users to host users
3. **Adjust the Dockerfile** to use a specific UID/GID that matches the host
4. **Modify the init-permissions command** to set more restrictive permissions (e.g., `755` or `775`)


