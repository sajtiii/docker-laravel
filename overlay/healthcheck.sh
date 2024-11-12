#!/bin/sh -e

source /scripts/functions.sh
load_config common
load_service_configs

if [ -f "${APP_PATH}/healthcheck.sh" ]; then
    source ${APP_PATH}/healthcheck.sh
    exit 0
fi

source /scripts/configs/healthcheck.sh

echo $(($(date +%s) % $QUEUE_TIMEOUT))

if [ "${WEB_HEALTHCHECK_ENABLED}" = true ] && [[ $CONTAINER_ROLE == *"web"* ]]; then
    if [ "${OCTANE_ENABLED}" = true ] ; then
        php ${APP_PATH}/artisan octane:status || exit 1
    fi
    curl --fail --silent --max-time ${WEB_HEALTHCHECK_TIMEOUT} "${WEB_HEALTHCHECK_URL}" || exit 1
fi

if [ "${QUEUE_HEALTHCHECK_ENABLED}" = true ] && [[ $CONTAINER_ROLE == *"queue"* ]]; then
    IFS=','
    for queue in $QUEUES; do
        length=$(php ${APP_PATH}/artisan tinker --execute="echo Queue::size('${queue}')")
        file="/tmp/queue-length-${queue}"
        previousLength=0
        if [ -f $file ]; then
            previousLength=$(head -n 1 $file)
        fi

        echo $length > $file

        if [ $length -gt 0 ] && [ $length -eq $previousLength ]; then
            exit 1
        fi
    done
fi

# if [ "${SCHEDULER_HEALTHCHECK_ENABLED}" = true ] && [[ $CONTAINER_ROLE == *"scheduler"* ]]; then
#     echo "Scheduler TODO";
# fi

exit 0;