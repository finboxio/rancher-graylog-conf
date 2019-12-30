#!/bin/bash

set -e

GRAYLOG_DATA_DIR=${GRAYLOG_DATA_DIR:-/usr/local/graylog/data}
GRAYLOG_HOME=${GRAYLOG_HOME:-/usr/share/graylog}

while [[ ! -e /etc/rancher-conf/graylog/graylog.conf ]]; do
  echo 'waiting for graylog configuration'
  sleep 2
done

[[ -d "${GRAYLOG_DATA_DIR}" ]] || mkdir -p "${GRAYLOG_DATA_DIR}"
ln -sf $GRAYLOG_DATA_DIR $GRAYLOG_HOME/data

[[ -d "${GRAYLOG_HOME}/data/config" ]] || mkdir -p "${GRAYLOG_HOME}/data/config"

cp /etc/rancher-conf/graylog/graylog.conf $GRAYLOG_HOME/data/config/graylog.conf
cp /etc/rancher-conf/graylog/log4j2.xml $GRAYLOG_HOME/data/config/log4j2.xml

exec /docker-entrypoint.sh "$@"
