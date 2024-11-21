#!/bin/sh -e

export WEB_HEALTHCHECK_ENABLED=${WEB_HEALTHCHECK_ENABLED:-true}
export WEB_HEALTHCHECK_PATH=${WEB_HEALTHCHECK_PATH:-up}
export WEB_HEALTHCHECK_URL=${WEB_HEALTHCHECK_URL:-http://localhost:${PORT}/${WEB_HEALTHCHECK_PATH}}
export WEB_HEALTHCHECK_TIMEOUT=${WEB_HEALTHCHECK_TIMEOUT:-1}
export QUEUE_HEALTHCHECK_ENABLED=${QUEUE_HEALTHCHECK_ENABLED:-true}
export SCHEDULER_HEALTHCHECK_ENABLED=${SCHEDULER_HEALTHCHECK_ENABLED:-true}
