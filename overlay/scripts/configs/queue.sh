#!/bin/sh

export QUEUES=${QUEUES:-high,medium,notification,default,low}
export QUEUE_TRIES=${QUEUE_TRIES:-3}
export QUEUE_TIMEOUT=${QUEUE_TIMEOUT:-7200}