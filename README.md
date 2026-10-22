# Laravel Docker

Just a simple docker image used to run laravel applications with or withput octane. \
It also incorporates queue and scheduler services.
The services can be selected using the `CONTAINER_ROLE` environment variable.
`CONTAINER_ROLE` can be any of the following: `web`, `queue`, `scheduler` or `cmd`, or a combination of them, like: `web,scheduler`, `web,queue`, `queue,scheduler` or `web,queue,scheduler`

## Change in versioning schema
The project initially followed the Laravel versioning scheme (eg.: `:v11` container for Laravel 11), but it is not changed, and the project follows semantic versioning from `v1`.

## Image tags

| Tag                                | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `latest`, `vX.Y.Z`, `vX.Y`, `vX`   | Release builds, on the newest supported PHP version (8.5)                   |
| `phpX.Y`, `vX.Y.Z-phpX.Y`          | Release builds for a specific PHP version                                   |
| `edge`, `edge-phpX.Y`              | Latest `main` branch builds                                                 |
| `nightly`, `nightly-phpX.Y`        | Rebuilt every night from `main` without cache, to pick up base image and package updates |

The nightly images are scanned with [Trivy](https://trivy.dev). Fixable `HIGH` and `CRITICAL` vulnerabilities are tracked in one issue per PHP version (label `nightly-scan`), which is closed automatically when the findings are gone.

## Compatibility matrix

Multiple PHP versions are available from the container, which are compatible with the following Laraver versions:

|            | PHP 8.2 | PHP 8.3 | PHP 8.4 | PHP 8.5 |
|------------|:-------:|:-------:|:-------:|:-------:|
| Laravel 9  | &check; |         |         |         |
| Laravel 10 | &check; | &check; |         |         |
| Laravel 11 | &check; | &check; | &check; | &check; |
| Laravel 12 | &check; | &check; | &check; | &check; |
| Laravel 13 |         | &check; | &check; | &check; |

Laravel 9, 10 and 11 are end of life upstream, they are still tested for legacy applications, but Laravel does not provide fixes for them anymore.

## Upgrading to v2

The image is based on [`shinsenter/frankenphp`](https://hub.docker.com/r/shinsenter/frankenphp) and runs with less privileges. Things to be aware of when coming from v1:

- **Default port is `8080`** instead of `80`, so no extra capability is needed. Set `PORT` to change it, and publish it accordingly (`-p 80:8080`). `EXPOSE`, the healthcheck and the Caddy config follow `PORT`.
- **Everything runs as the `app` user (`1000:1000`) by default**: the web server, queue worker, scheduler, `artisan` commands run by the entrypoint (migrations, caches) and the `cmd` role. Only the entrypoint and `supervisord` (used when multiple roles are combined) stay root, to start the processes. Set `PUID` and `PGID` to run as another numeric user and group (no passwd entry is needed). Volumes with files owned by the v1 `www-data` user (uid 82) have to be `chown`ed. `storage` and `bootstrap/cache` must be writable by that user (see `Dockerfile.example`).
- **The scheduler no longer uses cron.** It runs `artisan schedule:run` at the start of every minute from a small loop, without root and without waiting for overlapping runs.
- **The Caddy admin API listens on `localhost` only** (`CADDY_ADMIN_PORT`, default `2019`, the Caddy default), so it is not reachable from other containers.
- **Hardened PHP defaults**: `expose_php`, `display_errors` and `allow_url_include` are off, sessions use strict mode and `HttpOnly`, `SameSite=Lax` cookies. Override them with your own ini file in `$PHP_INI_DIR/conf.d`.
- **Extensions**: all extensions needed by Laravel and Octane (including `pcntl`, `redis`, `gd`, `intl`, `zip`) come with the base image. Composer and `install-php-extensions` are also included, so they do not have to be installed in projects built on this image.

## Running hardened

The image can run with a read-only filesystem and without any extra privileges. The runtime only needs to be able to switch to the `PUID`/`PGID` user (`app`, `1000:1000` by default), and write to the `tmpfs` mounts and volumes below:

```yaml
services:
  app:
    image: ghcr.io/sajtiii/docker-laravel:latest
    read_only: true
    cap_drop:
      - ALL
    cap_add:
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp:mode=1777
      - /config:mode=1777
      - /data:mode=1777
    volumes:
      - storage:/srv/http/storage
      - bootstrap-cache:/srv/http/bootstrap/cache
```

Everything else the application writes (for example a SQLite database) has to live on a volume as well. See `docker-compose.yml` for a complete example.

## Supply chain

- The base image is rebuilt upstream whenever PHP or Alpine publish updates, and this image is rebuilt every night to pick them up.
- Every image is built with SBOM and max provenance attestations, and non-PR images are signed with [cosign](https://docs.sigstore.dev/cosign/overview/) (keyless). Verify with:

  ```sh
  cosign verify ghcr.io/sajtiii/docker-laravel:latest \
    --certificate-identity-regexp 'https://github.com/sajtiii/docker-laravel/.*' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```
- Pull requests get a [Trivy](https://trivy.dev) report per PHP version as a comment, and a release is not published if it contains a fixable `CRITICAL` vulnerability.
- The workflows run with minimal permissions.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` (the `app` user) | Numeric user ID the application processes run as. |
| `PGID` | `1000` (the `app` group) | Numeric group ID the application processes run as. |

## Development
A new laravel app (with octane optionally) installed inside the `www` folder is required. \
To install a fresh laravel in that folder run the following commands:

- `curl -s https://laravel.build/www?with=none | bash`
- `cd www`
- `./vendor/bin/sail up -d`
- `./vendor/bin/sail composer require laravel/octane`
- `./vendor/bin/sail artisan octane:install --server=frankenphp`
- `./vendor/bin/sail down`

After this, the `Dockerfile.example` can be used. A `docker-compose.yml` file is also provided for this purpose.
