#//bin/sh

trigger() {
    if [ -f "/${APP_PATH}/${1}.sh" ] ; then
        echo "Running $1 script [/${APP_PATH}/${1}.sh] ..."
        chmod +x /${APP_PATH}/${1}.sh
        source /${APP_PATH}/${1}.sh
    fi
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
    if [[ "${CONTAINER_ROLE}" == *"web"* ]]; then
        load_config web
    fi
    if [[ "${CONTAINER_ROLE}" == *"queue"* ]]; then
        load_config queue
    fi
    if [[ "${CONTAINER_ROLE}" == *"scheduler"* ]]; then
        load_config scheduler
    fi
}