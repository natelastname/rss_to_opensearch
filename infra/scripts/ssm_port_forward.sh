#!/bin/bash
# Created on 2025-09-12T15:27:06-04:00
# Author: nate

set -eo pipefail
DIR=$(dirname "$(readlink -f "$0")")

EC2_ID="$(tofu output -raw ec2_instance_id)"

aws ssm start-session \
  --target "$EC2_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters 'localPortNumber=["5601"],portNumber=["5601"]'
# then browse http://localhost:5601
