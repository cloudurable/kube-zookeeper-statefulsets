FROM ubuntu:18.04
ENV ZK_USER=zookeeper \
ZK_DATA_DIR=/var/lib/zookeeper/data \
ZK_DATA_LOG_DIR=/var/lib/zookeeper/log \
ZK_LOG_DIR=/var/log/zookeeper \
ZK_CONF_DIR=/opt/zookeeper/conf \
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64  \
JAVA_DIST=openjdk-11-jre-headless

ARG ZK_DIST=zookeeper-3.4.14

RUN set -x \
    && apt-get update


RUN set -x \
        && echo "Installing Java" \
        && apt-get install -y  $JAVA_DIST

RUN set -x \
        && apt-get install -y  netcat-openbsd wget gnupg

RUN set -x \
        && echo "Downloading ZooKeeper" \
    	  && wget -q "http://www.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz" \
        && wget -q "http://www.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz.asc"

RUN set -x && wget -q  "http://www.apache.org/dist/zookeeper/KEYS"

RUN set -x && echo "ZooKeeper RESOURCES DOWNLOADED!"

RUN set -x && export GNUPGHOME="$(mktemp -d)" \
            && gpg --import KEYS \
            && gpg --batch --verify "$ZK_DIST.tar.gz.asc" "$ZK_DIST.tar.gz" \
            && tar -xzf "$ZK_DIST.tar.gz" -C /opt \
            && rm -r "$GNUPGHOME" "$ZK_DIST.tar.gz" "$ZK_DIST.tar.gz.asc" KEYS \
            && ln -s /opt/$ZK_DIST /opt/zookeeper

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
        /opt/zookeeper/$ZK_DIST.jar.asc \
        /opt/zookeeper/$ZK_DIST.jar.md5 \
        /opt/zookeeper/$ZK_DIST.jar.sha1 \
    	&& apt-get autoremove -y wget \
    	&& rm -rf /var/lib/apt/lists/*

    #Copy configuration generator script to bin
COPY scripts /opt/zookeeper/bin/

    # Create a user for the zookeeper process and configure file system ownership
    # for necessary directories and symlink the distribution as a user executable
RUN set -x \
    	&& useradd $ZK_USER \
        && [ `id -u $ZK_USER` -eq 1000 ] \
        && [ `id -g $ZK_USER` -eq 1000 ]

RUN set -x \
      && mkdir -p $ZK_DATA_DIR $ZK_DATA_LOG_DIR $ZK_LOG_DIR /usr/share/zookeeper /tmp/zookeeper /usr/etc/ \
    	&& chown -R "$ZK_USER:$ZK_USER" /opt/$ZK_DIST $ZK_DATA_DIR $ZK_LOG_DIR $ZK_DATA_LOG_DIR /tmp/zookeeper \
    	&& ln -s /opt/zookeeper/conf/ /usr/etc/zookeeper \
    	&& ln -s /opt/zookeeper/bin/* /usr/bin \
    	&& ln -s /opt/zookeeper/$ZK_DIST.jar /usr/share/zookeeper/ \
    	&& ln -s /opt/zookeeper/lib/* /usr/share/zookeeper


RUN set -x \
      &&  chgrp -R 0 "$ZK_DATA_LOG_DIR" "$ZK_DATA_DIR" "$ZK_CONF_DIR" "$ZK_LOG_DIR"  \
                  "/usr/bin/start.sh" "/usr/bin/metrics.sh" "/usr/bin/ready_live.sh"

RUN set -x \
      && chmod -R g=u "$ZK_DATA_LOG_DIR" "$ZK_DATA_DIR" "$ZK_CONF_DIR" "$ZK_LOG_DIR" \
                        "/opt/zookeeper/bin/start.sh" "/opt/zookeeper/bin/metrics.sh" "/opt/zookeeper/bin/ready_live.sh"

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/start.sh

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/metrics.sh

RUN set -x \
            && chmod 777 /opt/zookeeper/bin/ready_live.sh
