#!/bin/sh

# Runs the Laravel scheduler at the start of every minute, without cron and without root.
# The healthcheck reads the timestamp of the last run.

while true; do
    date +%s > /tmp/scheduler-last-run
    php ${APP_PATH}/artisan schedule:run --verbose --no-interaction || true
    sleep $((60 - $(date +%s) % 60))
done
