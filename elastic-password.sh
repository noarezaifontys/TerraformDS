#!/bin/bash
set -euo pipefail

# Locate the ES pod
POD_NAME=$(kubectl get pod -n default -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [[ -z "$POD_NAME" ]]; then
  echo '{"result":"ERROR: Elasticsearch pod not found"}'
  exit 0
fi

# Attempt reset (or detect “already”)
RAW_OUTPUT=$(kubectl exec -n default "$POD_NAME" -- bin/elasticsearch-reset-password -u elastic -b 2>&1 || true)
if echo "$RAW_OUTPUT" | grep -qi "already"; then
  echo '{"result":"PASSWORD_ALREADY_SET"}'
  exit 0
fi

# Temporarily disable -e so grep failure doesn’t kill us
set +e
PASSWORD=$(echo "$RAW_OUTPUT" | grep "New value" | awk '{print $NF}' | tr -d '\r\n')
set -e

if [[ -z "$PASSWORD" ]]; then
  echo '{"result":"ERROR: Password not found in output"}'
  exit 0
fi

# All good
echo "{\"result\":\"$PASSWORD\"}"
