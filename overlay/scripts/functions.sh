#//bin/sh

trigger() {
    if [ -f "${APP_PATH}/${1}.sh" ] ; then
        echo "Triggering $1 script [${APP_PATH}/${1}.sh] ..."
        chmod +x ${APP_PATH}/${1}.sh
        source ${APP_PATH}/${1}.sh
    fi
}

is_web() {
    [[ $CONTAINER_ROLE == *"web"* ]]
}

is_queue() {
    [[ $CONTAINER_ROLE == *"queue"* ]]
}

is_scheduler() {
    [[ $CONTAINER_ROLE == *"scheduler"* ]]
}

message() {
    length=${#1}
    echo ""
    i=0
    while [ $i -lt $length ]; do echo -n "#"; i=$((i + 1)); done
    echo "######"
    echo -n "#  "
    i=0
    while [ $i -lt $length ]; do echo -n " "; i=$((i + 1)); done
    echo "  #"
    echo "#  $1  #"
    echo -n "#  "
    i=0
    while [ $i -lt $length ]; do echo -n " "; i=$((i + 1)); done
    echo "  #"
    i=0
    while [ $i -lt $length ]; do echo -n "#"; i=$((i + 1)); done
    echo "######"
    echo ""
}

load_config() {
    source /scripts/configs/$1.sh
}

load_service_configs() {
    if is_web; then
        load_config web
    fi
    if is_queue; then
        load_config queue
    fi
    if is_scheduler; then
        load_config scheduler
    fi
}