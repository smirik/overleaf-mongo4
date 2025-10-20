# Overleaf CE for MongoDB 4.4

A fork of [Overleaf Community Edition](https://github.com/overleaf/overleaf) v4.1.6 compatible with MongoDB 4.4, designed for older servers without AVX CPU support (e.g., Synology NAS).

## Why This Fork?

Modern Overleaf (v5.0+) requires MongoDB 5.0+, which **requires AVX CPU instruction set**. Many older servers don't support AVX, making current Overleaf versions incompatible.

This fork solves that by using:

- Overleaf CE 4.1.6
- MongoDB 4.4 (no AVX requirement)
- TeX Live 2023 with common packages pre-installed

## Warning

⚠️ MongoDB 4.4 reached **end-of-life in February 2024**. Use this only if you cannot upgrade your hardware.

## Quick Start

1. Update `docker-compose.yml` with your settings:

   - Volume paths (currently set for Synology `/volume1/docker/overleaf`)
   - Port (default: 7643)
   - Email/SMTP configuration
   - Site URL
   - User's data

2. Launch:

   ```bash
   docker-compose up -d
   ```

3. Create admin user:
   ```bash
   docker exec -it Overleaf /bin/bash -c "cd /overleaf/services/web && node modules/server-ce-scripts/scripts/create-admin-user.js admin@example.org"
   ```

## Included LaTeX Packages

The project builds its own overleaf's docker image to include the most used packages.

Pre-installed: `biber`, `biblatex-apa`, `apa7`, `aastex`, `tikz`, `pgfplots`, `siunitx`, and more. See `Dockerfile` for full list.

## License

AGPLv3 (same as Overleaf CE) for the Overleaf's part. The rest — MIT.
