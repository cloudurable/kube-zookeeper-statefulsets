FROM ubuntu:18.04
ENV ZOOKEEPER_USER=zookeeper \
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64  \
JAVA_DIST=openjdk-11-jre-headless \
ZOOKEEPER_LOG_LEVEL=INFO \
ZOOKEEPER_DATA_DIR="/var/lib/zookeeper/data" \
ZOOKEEPER_DATA_LOG_DIR="/var/lib/zookeeper/log" \
ZOOKEEPER_LOG_DIR="/var/log/zookeeper" \
ZOOKEEPER_CONF_DIR="/opt/zookeeper/conf" \
ZOOKEEPER_CLIENT_PORT=2181 \
ZOOKEEPER_SERVER_PORT=2888 \
ZOOKEEPER_ELECTION_PORT=3888 \
ZOOKEEPER_TICK_TIME=2000 \
ZOOKEEPER_INIT_LIMIT=10 \
ZOOKEEPER_SYNC_LIMIT=5 \
ZOOKEEPER_HEAP=2G \
ZOOKEEPER_MAX_CLIENT_CNXNS=60 \
ZOOKEEPER_SNAP_RETAIN_COUNT=3 \
ZOOKEEPER_PURGE_INTERVAL=0 \
ZOOKEEPER_SERVERS=1

ARG ZOOKEEPER_DIST=zookeeper-3.4.14

RUN set -x \
    && apt-get update


RUN set -x \
        && echo "Installing Java" \
        && apt-get install -y  $JAVA_DIST

RUN set -x \
        && apt-get install -y  netcat-openbsd wget gnupg

RUN set -x \
        && echo "Downloading ZooKeeper" \
    	  && wget -q "http://www.apache.org/dist/zookeeper/$ZOOKEEPER_DIST/$ZOOKEEPER_DIST.tar.gz" \
        && wget -q "http://www.apache.org/dist/zookeeper/$ZOOKEEPER_DIST/$ZOOKEEPER_DIST.tar.gz.asc"

RUN set -x && wget -q  "http://www.apache.org/dist/zookeeper/KEYS"

RUN set -x && echo "ZooKeeper RESOURCES DOWNLOADED!"

RUN set -x && export GNUPGHOME="$(mktemp -d)" \
            && gpg --import KEYS \
            && gpg --batch --verify "$ZOOKEEPER_DIST.tar.gz.asc" "$ZOOKEEPER_DIST.tar.gz" \
            && tar -xzf "$ZOOKEEPER_DIST.tar.gz" -C /opt \
            && rm -r "$GNUPGHOME" "$ZOOKEEPER_DIST.tar.gz" "$ZOOKEEPER_DIST.tar.gz.asc" KEYS \
            && ln -s /opt/$ZOOKEEPER_DIST /opt/zookeeper

RUN set -x && echo "ZOOKEEPER INSTALLED!"

RUN set -x \
        && rm -rf /opt/zookeeper/CHANGES.txt \
        /opt/zookeeper/README.txt \
        /opt/zookeeper/NOTICE.txt \
        /opt/zookeeper/CHANGES.txt \
        /opt/zookeeper/README_packaging.txt \
        /opt/zookeeper/build.xml \
        /opt/zookeeper/config \
        /opt/zookeeper/contrib \
        /opt/zookeeper/dist-maven \
        /opt/zookeeper/docs \
        /opt/zookeeper/ivy.xml \
        /opt/zookeeper/ivysettings.xml \
        /opt/zookeeper/recipes \
        /opt/zookeeper/src \
        /opt/zookeeper/$ZOOKEEPER_DIST.jar.asc \
        /opt/zookeeper/$ZOOKEEPER_DIST.jar.md5 \
        /opt/zookeeper/$ZOOKEEPER_DIST.jar.sha1 \
    	&& apt-get autoremove -y wget \
    	&& rm -rf /var/lib/apt/lists/*

    #Copy configuration generator script to bin
COPY scripts /opt/zookeeper/bin/

    # Create a user for the zookeeper process and configure file system ownership
    # for necessary directories and symlink the distribution as a user executable
RUN set -x \
    	&& useradd $ZOOKEEPER_USER \
        && [ `id -u $ZOOKEEPER_USER` -eq 1000 ] \
        && [ `id -g $ZOOKEEPER_USER` -eq 1000 ]

RUN set -x \
      && mkdir -p $ZOOKEEPER_DATA_DIR $ZOOKEEPER_DATA_LOG_DIR $ZOOKEEPER_LOG_DIR /usr/share/zookeeper /tmp/zookeeper /usr/etc/ \
    	&& chown -R "$ZOOKEEPER_USER:$ZOOKEEPER_USER" /opt/$ZOOKEEPER_DIST $ZOOKEEPER_DATA_DIR $ZOOKEEPER_LOG_DIR $ZOOKEEPER_DATA_LOG_DIR /tmp/zookeeper \
    	&& ln -s /opt/zookeeper/conf/ /usr/etc/zookeeper \
    	&& ln -s /opt/zookeeper/bin/* /usr/bin \
    	&& ln -s /opt/zookeeper/$ZOOKEEPER_DIST.jar /usr/share/zookeeper/ \
    	&& ln -s /opt/zookeeper/lib/* /usr/share/zookeeper


RUN set -x \
                  && chmod 777 $ZOOKEEPER_DATA_DIR $ZOOKEEPER_LOG_DIR $ZOOKEEPER_DATA_LOG_DIR
RUN set -x \
      &&  chgrp -R 0 "$ZOOKEEPER_DATA_LOG_DIR" "$ZOOKEEPER_DATA_DIR" "$ZOOKEEPER_CONF_DIR" "$ZOOKEEPER_LOG_DIR"  \
                  "/usr/bin/start.sh" "/usr/bin/metrics.sh" "/usr/bin/ready_live.sh"

RUN set -x \
      && chmod -R g=u "$ZOOKEEPER_DATA_LOG_DIR" "$ZOOKEEPER_DATA_DIR" "$ZOOKEEPER_CONF_DIR" "$ZOOKEEPER_LOG_DIR" \
                        "/opt/zookeeper/bin/start.sh" "/opt/zookeeper/bin/metrics.sh" "/opt/zookeeper/bin/ready_live.sh"

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/start.sh

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/metrics.sh

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/ready_live.sh
