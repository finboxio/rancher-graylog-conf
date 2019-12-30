FROM finboxio/rancher-conf-aws:v0.3.1

ADD config.toml /etc/rancher-conf/
ADD graylog.conf.tmpl /etc/rancher-conf/
ADD log4j2.xml.tmpl /etc/rancher-conf/
ADD setup.sh /etc/rancher-conf/
ADD run.sh /opt/rancher/bin/
