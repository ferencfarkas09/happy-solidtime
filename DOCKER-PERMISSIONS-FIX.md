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

## Solution
Change the `logs/` and `app-storage/` directories to be world-writable (`777`):

```bash
chmod -R 777 ./1-docker-with-database/logs
chmod -R 777 ./1-docker-with-database/app-storage
chmod -R 777 ./0-docker-traefik-with-database/logs
chmod -R 777 ./0-docker-traefik-with-database/app-storage
```

Or simply run the provided script:
```bash
./fix-permissions.sh
```

## How This Works
- Permissions `777` (drwxrwxrwx) means: Owner, Group, and Others all have read, write, and execute permissions
- This allows the Docker container processes to write files regardless of their user ID
- The container processes can now successfully create and append to log files

## Prevention
To prevent this issue when cloning or setting up the project:
1. Run `fix-permissions.sh` after cloning the repository
2. Or manually set permissions as shown above
3. Ensure these directories remain writable by adding them to `.gitignore` if needed

## Alternative Solutions
If you want more restrictive permissions, you could:
1. **Change the docker-compose.yml** to run all services as your local user
2. **Use Docker user namespace remapping** to map container users to host users
3. **Adjust the Dockerfile** to use a specific UID/GID that matches the host

For now, the `777` permission fix ensures the application works correctly.

