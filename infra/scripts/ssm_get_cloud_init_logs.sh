#!/bin/bash
# Created on 2025-09-12T15:27:06-04:00
# Author: nate


set -eo pipefail
DIR=$(dirname "$(readlink -f "$0")")

EC2_ID="$(tofu output -raw ec2_instance_id)"
PROJECT_NAME="$(tofu output -raw project)"
SERVICE="$PROJECT_NAME.service"

# Build a small JSON file for the session parameters (avoids nasty quoting)
PARAMS_FILE="$(mktemp)"
trap 'rm -f "$PARAMS_FILE"' EXIT

cat >"$PARAMS_FILE" <<JSON
{"command": ["sudo bash -lc 'cloud-init status --long'"]}
JSON

# Start an interactive command session that streams the logs
aws ssm start-session \
  --target "$EC2_ID" \
  --document-name AWS-StartInteractiveCommand \
  --parameters file://"$PARAMS_FILE"
