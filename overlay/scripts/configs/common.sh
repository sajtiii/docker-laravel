#!/bin/sh -e

# Set default env vars
export CONTAINER_ROLE=${CONTAINER_ROLE:-web,queue,scheduler}

export APP_PATH=${APP_PATH:-/srv/http}

export UPLOAD_LIMIT=${UPLOAD_LIMIT:-20M}
