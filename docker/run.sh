#!/bin/bash
# Created on 2025-09-03T15:51:11-04:00
# Author: nate

set -eo pipefail
DIR=$(dirname "$(readlink -f "$0")")


#docker run --rm rss_to_opensearch:latest

# When you want it to interface with an opensearch instance already running on localhost
docker run -it --rm \
    --add-host=host.docker.internal:host-gateway \
    -e OPENSEARCH_HOST=host.docker.internal \
    -e OPENSEARCH_PORT=9200 \

    myproj:poetry

