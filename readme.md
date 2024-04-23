# Laravel Docker

It's just a simple docker image used to run laravel applications with octane. \
It also incorporates queue and scheduler modes, that can be selected using the `CONTAINER_ROLE` environment variable.
`CONTAINER_ROLE` can be any of the following: `web`, `queue`, `scheduler` or `cmd`, or a combination of them, like: `web,scheduler`, `web,queue`, `queue,scheduler` or `web,queue,scheduler`

#### For Development
A new laravel app with octane installed is required inside the `www` folder. \
To install a fresh laravel in that folder run the following commands:

- `curl -s https://laravel.build/www?with=none | bash`
- `cd www`
- `./vendor/bin/sail up -d`
- `./vendor/bin/sail composer require laravel/octane`
- `./vendor/bin/sail artisan octane:install`
- `./vendor/bin/sail down`

After this, the `Dockerfile.example` can be used. A `docker-compose.yml` file is also provided for this purpose.