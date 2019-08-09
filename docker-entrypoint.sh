#!/bin/bash

set -e

setDefaults() {
  export MONGO_HOST=${MONGO_HOST:="$(env | grep MONGO.*PORT_.*_TCP_ADDR= | sed -e 's|.*=||')"}
  export MONGO_TCP_PORT=${MONGO_TCP_PORT:="$(env | grep MONGO.*PORT_.*_TCP_PORT= | sed -e 's|.*=||')"}
  export POSTGRES_HOST=${POSTGRES_HOST:="$(env | grep POSTGRES.*PORT_.*_TCP_ADDR= | sed -e 's|.*=||')"}
  export POSTGRES_TCP_PORT=${POSTGRES_TCP_PORT:="$(env | grep POSTGRES.*PORT_.*_TCP_PORT= | sed -e 's|.*=||')"}
  env | grep -E "^MONGO.*|^POSTGRES.*" | sort -n
}

# Wait for. Params: host, port, service
waitFor() {
    echo -n "===> Waiting for ${3}(${1}:${2}) to start..."
    i=1
    while [ $i -le 20 ]; do
        if nc -vz ${1} ${2} 2>/dev/null; then
            echo "${3} is ready!"
            return 0
        fi

        echo -n '.'
        sleep 1
        i=$((i+1))
    done

    echo
    echo >&2 "${3} is not available"
    echo >&2 "Address: ${1}:${2}"
}

setUpCuckoo() {

  echo "===> Use default ports and hosts if not specified..."
  setDefaults
  
  echo "===> Update /opt/cuckoo/conf/reporting.conf if needed..."
  ./update_conf.py
  
  echo
  if [ ! "$MONGO_HOST" == "" ]; then
  	waitFor ${MONGO_HOST} ${MONGO_TCP_PORT} MongoDB
  fi
  
  echo
  if [ ! "$POSTGRES_HOST" == "" ]; then
  	waitFor ${POSTGRES_HOST} ${POSTGRES_TCP_PORT} Postgres
  fi
}

setUpCuckoo

if [ -z "$MONGO_HOST" ]; then
  echo >&2 "[ERROR] MongoDB cannot be found. Please link mongo and try again..."
  exit 1
fi

#set -- su-exec cuckoo /sbin/tini -- cuckoo web runserver 0.0.0.0:CUCKOO_WEB_PORT
set -- cuckoo web runserver 0.0.0.0:$CUCKOO_UI_PORT

exec "$@"
