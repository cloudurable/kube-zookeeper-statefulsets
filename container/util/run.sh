#!/bin/bash
source util/env.sh
docker run -it  $REPO_FULL /opt/zookeeper/bin/start.sh
