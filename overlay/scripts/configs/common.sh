#!/bin/sh

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export APP_ENV=${APP_ENV:-production}