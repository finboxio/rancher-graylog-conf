#!/bin/bash

set -e

GRAYLOG_DATA_DIR=${GRAYLOG_DATA_DIR:-/usr/share/graylog/data}

while [[ ! -e /etc/rancher-conf/graylog.conf ]]; do
  echo 'waiting for graylog configuration'
  sleep 2
done

if [ "$1" = "" ]; then
  set -- graylog
fi

if [ "${1:0:1}" = '-' ]; then
  set -- graylog "$@"
fi

# Delete outdated PID file
rm -f /tmp/graylog.pid

# Create data directories
if [ "$1" = 'graylog' -a "$(id -u)" = '0' ]; then
  for d in journal log plugin config contentpacks; do
    dir=${GRAYLOG_DATA_DIR}/$d
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
    fi
    if [ "$(stat --format='%U:%G' $dir)" != 'graylog:graylog' ]; then
      chown -R graylog:graylog "$dir"
    fi
  done

  chmod +r /etc/rancher-conf/graylog.conf
  chmod +r /etc/rancher-conf/log4j2.xml

  sed -e "s/\/usr\/share\/graylog\/data/$(echo $GRAYLOG_DATA_DIR | sed 's/\//\\\//g')/g" -i /etc/rancher-conf/graylog.conf

  # Start Graylog server
  set -- gosu graylog "$JAVA_HOME/bin/java" $GRAYLOG_SERVER_JAVA_OPTS \
      -jar \
      -Dlog4j.configurationFile=/etc/rancher-conf/log4j2.xml \
      -Djava.library.path=/usr/share/graylog/lib/sigar/ \
      -Dgraylog2.installation_source=docker /usr/share/graylog/graylog.jar \
      server \
      -f /etc/rancher-conf/graylog.conf
fi

# Allow the user to run arbitrarily commands like bash
exec "$@"
