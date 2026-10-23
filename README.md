# Laravel Docker

Just a simple Docker image used to run Laravel applications with or without Octane. \
It also incorporates queue and scheduler services.
The services can be selected using the `CONTAINER_ROLE` environment variable.
`CONTAINER_ROLE` can be any of the following: `web`, `queue`, `scheduler` or `cmd`, or a combination of them, like: `web,scheduler`, `web,queue`, `queue,scheduler` or `web,queue,scheduler`

## Change in versioning schema
The project initially followed the Laravel versioning scheme (e.g. `:v11` container for Laravel 11), but this has changed, and the project follows semantic versioning since `v1`.

## Image tags

| Tag                                | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `latest`, `vX.Y.Z`, `vX.Y`, `vX`   | Release builds, on the newest supported PHP version (8.5)                   |
| `phpX.Y`, `vX.Y.Z-phpX.Y`          | Release builds for a specific PHP version                                   |
| `edge`, `edge-phpX.Y`              | Latest `main` branch builds                                                 |
| `nightly`, `nightly-phpX.Y`        | Rebuilt every night from `main` without cache, to pick up base image and package updates |

The nightly workflow scans these images with [Trivy](https://trivy.dev) and tracks fixable `HIGH` and `CRITICAL` vulnerabilities in one issue per PHP version (label `nightly-scan`). It closes the issue once the findings are gone.

## Compatibility matrix

Multiple PHP versions are available from the container, which are compatible with the following Laravel versions:

|            | PHP 8.2 | PHP 8.3 | PHP 8.4 | PHP 8.5 |
|------------|:-------:|:-------:|:-------:|:-------:|
| Laravel 9  | &check; |         |         |         |
| Laravel 10 | &check; | &check; |         |         |
| Laravel 11 | &check; | &check; | &check; | &check; |
| Laravel 12 | &check; | &check; | &check; | &check; |
| Laravel 13 |         | &check; | &check; | &check; |

Laravel 9, 10 and 11 are end of life upstream. The CI still tests them for legacy applications, but Laravel no longer fixes them.

## Upgrading to v2

The image is based on [`shinsenter/frankenphp`](https://hub.docker.com/r/shinsenter/frankenphp) and runs with fewer privileges. Changes since v1:

- **Default port 8080.** The app listens on `8080` instead of `80`, so it needs no extra capability. Set `PORT` to change it and publish that port (`-p 80:8080`). The healthcheck and the Caddy config follow `PORT`, but `EXPOSE` always says `8080`.
- **Non-root processes.** The web server, queue worker, scheduler, the `cmd` role and the `artisan` commands the entrypoint runs (migrations, caches) all run as the `app` user (`1000:1000`). Only the entrypoint, the s6 supervisor and the application hook scripts (`preconfig.sh`, `postconfig.sh`, `premigrate.sh`, `postmigrate.sh`, `prestart.sh` and `healthcheck.sh` in the application directory) run as root.
- **`PUID` and `PGID`.** Set them to run as another numeric user and group. The user does not need a passwd entry. That user must be able to write `storage` (see `Dockerfile.example`), so `chown` any volume with files owned by the v1 `www-data` user (uid 82).
- **The scheduler no longer uses cron.** A small loop runs `artisan schedule:run` at the start of every minute, without root. A run that takes longer than a minute delays the next one instead of overlapping it.
- **Caddy admin API on `localhost` only.** Other containers can not reach it. `CADDY_ADMIN_PORT` sets the port, which defaults to Caddy's own default, `2019`.
- **Runtime caches in `/tmp/laravel`.** The entrypoint rebuilds the config, route and event caches (`APP_CONFIG_CACHE`, `APP_ROUTES_CACHE`, `APP_EVENTS_CACHE`) and the compiled views (`VIEW_COMPILED_PATH`) there on every start. Compiled views no longer go to `storage/framework/views`.
- **No `bootstrap/cache` volume.** The directory does not have to be writable anymore. It only holds the package manifests that `composer install` writes at build time. Remove any volume mounted there, because it would keep the package manifests of the previous image.
- **s6 instead of supervisord.** When you combine roles, [s6](https://skarnet.org/software/s6/) supervises the services, so the image no longer contains Python. s6 restarts a crashed service after one second and keeps retrying.
- **Request body limit.** Caddy rejects request bodies larger than `UPLOAD_LIMIT` before they reach PHP.
- **No setuid or setgid binaries.** The build removes these bits from every file in the image.
- **Hardened PHP defaults.** `expose_php`, `display_errors` and `allow_url_include` are off. Sessions use strict mode and `HttpOnly`, `SameSite=Lax` cookies. To change them, add your own ini file to `$PHP_INI_DIR/conf.d`.
- **Bundled extensions and tools.** The base image has every extension Laravel and Octane need, including `pcntl`, `redis`, `gd`, `intl` and `zip`. It also has Composer and `install-php-extensions`, so projects built on this image do not have to install them.

## Running hardened

The image runs with a read-only filesystem and only two capabilities, `SETUID` and `SETGID`, which the entrypoint needs to switch to the `PUID`/`PGID` user. It only writes to the `tmpfs` mounts and the volume below:

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
```

Put anything else the application writes, such as a SQLite database, on a volume too. `docker-compose.yml` has a complete example.

## Supply chain

- The upstream project rebuilds the base image whenever PHP or Alpine publish updates, and the nightly workflow rebuilds this image to pick them up.
- CI builds every image with SBOM and max provenance attestations, and signs every image outside pull requests with [cosign](https://docs.sigstore.dev/cosign/overview/) (keyless). To verify a signature:

  ```sh
  cosign verify ghcr.io/sajtiii/docker-laravel:latest \
    --certificate-identity-regexp 'https://github.com/sajtiii/docker-laravel/.*' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```
- Each pull request gets a [Trivy](https://trivy.dev) report per PHP version as a comment. The publish workflow does not release an image with a fixable `CRITICAL` vulnerability.
- The workflows run with minimal permissions.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` (the `app` user) | Numeric user ID the application processes run as. |
| `PGID` | `1000` (the `app` group) | Numeric group ID the application processes run as. |

## Development
A new Laravel app (optionally with Octane) installed inside the `www` folder is required. \
To install a fresh Laravel app in that folder, run the following commands:

- `curl -s https://laravel.build/www?with=none | bash`
- `cd www`
- `./vendor/bin/sail up -d`
- `./vendor/bin/sail composer require laravel/octane`
- `./vendor/bin/sail artisan octane:install --server=frankenphp`
- `./vendor/bin/sail down`

After this, the `Dockerfile.example` can be used. A `docker-compose.yml` file is also provided for this purpose.
