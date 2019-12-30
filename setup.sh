userdel graylog &>/dev/null
adduser -u 1100 graylog -D

if [[ "$EBS_VOLUME_DIR" != "" ]]; then
  chown -R graylog:graylog $EBS_VOLUME_DIR
fi

chown -R graylog:graylog /etc/rancher-conf/graylog
