# Laravel Docker

Just a simple docker image used to run laravel applications with or withput octane. \
It also incorporates queue and scheduler services.
The services can be selected using the `CONTAINER_ROLE` environment variable.
`CONTAINER_ROLE` can be any of the following: `web`, `queue`, `scheduler` or `cmd`, or a combination of them, like: `web,scheduler`, `web,queue`, `queue,scheduler` or `web,queue,scheduler`

## Change in versioning schema
The project initially followed the Laravel versioning scheme (eg.: `:v11` container for Laravel 11), but it is not changed, and the project follows semantic versioning from `v1`.

## Compatibility matrix

Multiple PHP versions are available from the container, which are compatible with the following Laraver versions:

|            | PHP 8.2 | PHP 8.3 |
|------------|:-------:|:-------:|
| Laravel 9  | &check; |         |
| Laravel 10 | &check; | &check; |
| Laravel 11 | &check; | &check; |


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