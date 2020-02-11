

VERSION="${$1:-0.0.1}"
REPO="${$2:-"kube-zookeeper"}"
ORGANIZATION="${$3:-"cloudurable}"
echo docker build --tag $ORGANIZATION/$REPO:$VERSION  .


RUN set -x \
    && echo "Installing Java" \
    && apt-get install -y  $JAVA_DIST

RUN set -x \
    && apt-get install -y  netcat-openbsd

RUN set -x \
    && echo "Downloading ZooKeeper" \
	  && wget -q "http://www.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz" \
    && wget -q "http://www.apache.org/dist/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz.asc"


RUN set -x && echo "RESOURCES DOWNLOADED!"

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
    && [ `id -g $ZK_USER` -eq 1000 ] \
    && mkdir -p $ZK_DATA_DIR $ZK_DATA_LOG_DIR $ZK_LOG_DIR /usr/share/zookeeper /tmp/zookeeper /usr/etc/ \
	&& chown -R "$ZK_USER:$ZK_USER" /opt/$ZK_DIST $ZK_DATA_DIR $ZK_LOG_DIR $ZK_DATA_LOG_DIR /tmp/zookeeper \
	&& ln -s /opt/zookeeper/conf/ /usr/etc/zookeeper \
	&& ln -s /opt/zookeeper/bin/* /usr/bin \
	&& ln -s /opt/zookeeper/$ZK_DIST.jar /usr/share/zookeeper/ \
	&& ln -s /opt/zookeeper/lib/* /usr/share/zookeeper
