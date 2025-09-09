#!/bin/bash
# Created on 2025-09-03T15:51:11-04:00
# Author: nate

set -eo pipefail
DIR=$(dirname "$(readlink -f "$0")")

docker run -it --rm rss_to_opensearch:latest bash

