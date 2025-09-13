#!/usr/bin/env bash
# Created on 2025-09-12T15:27:06-04:00
# Author: nate
set -euo pipefail

DIR=$(dirname "$(readlink -f "$0")")

# EC2_ID="$(tofu output -raw ec2_instance_id)"

# aws ssm start-session \
#   --target "$EC2_ID" \
#   --document-name AWS-StartPortForwardingSession \
#   --parameters 'localPortNumber=["5601"],portNumber=["5601"]'

# echo "###############################################################"
# echo "http://localhost:5601"
# echo "###############################################################"

######################################################################

#!/usr/bin/env bash
set -euo pipefail

EC2_ID="$(tofu output -raw ec2_instance_id 2>/dev/null || terraform output -raw ec2_instance_id)"
LOCAL_DASH="${1:-5601}"
LOCAL_OS="${2:-9200}"
REMOTE_DASH=5601
REMOTE_OS=9200

LOG1="/tmp/ssm-${LOCAL_DASH}.log"
LOG2="/tmp/ssm-${LOCAL_OS}.log"

P1=; P2=

cleanup() {
  echo
  echo "Stopping tunnels..."
  [[ -n "${P1:-}" ]] && kill "$P1" 2>/dev/null || true
  [[ -n "${P2:-}" ]] && kill "$P2" 2>/dev/null || true
}
# don't trap EXIT
trap cleanup INT TERM

start_pf() {
  local lp="$1" rp="$2" logfile="$3"
  aws ssm start-session \
    --target "$EC2_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters "localPortNumber=[\"$lp\"],portNumber=[\"$rp\"]" \
    >"$logfile" 2>&1 &
  echo $!
}

wait_port() {
  local port="$1"
  for _ in {1..80}; do
    (echo >"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  return 1
}

echo "Starting SSM port forwards to $EC2_ID..."
P1="$(start_pf "$LOCAL_DASH" "$REMOTE_DASH" "$LOG1")"
P2="$(start_pf "$LOCAL_OS" "$REMOTE_OS" "$LOG2")"

# Ensure both processes are alive
for pid in "$P1" "$P2"; do
  kill -0 "$pid" 2>/dev/null || { echo "Tunnel process $pid died early. See logs."; exit 1; }
done

if wait_port "$LOCAL_DASH" && wait_port "$LOCAL_OS"; then
  echo "✔ $LOCAL_DASH → $REMOTE_DASH ready → open:  http://localhost:$LOCAL_DASH"
  echo "✔ $LOCAL_OS   → $REMOTE_OS   ready → curl:  curl -k https://localhost:$LOCAL_OS"
  echo
  echo "(Logs: $LOG1, $LOG2. Press Ctrl-C to stop both tunnels.)"
else
  echo "Started, but local ports not accepting yet. See logs: $LOG1 / $LOG2"
fi

# Block here until user presses Ctrl-C or sessions die
while kill -0 "$P1" 2>/dev/null || kill -0 "$P2" 2>/dev/null; do
  sleep 1
done
