#!/bin/bash
set -euo pipefail

# all debug/info goes to stderr:
echo ">> Finding Elasticsearch pod..." >&2
POD_NAME=$(kubectl get pod -n default -l app=elasticsearch \
             -o jsonpath='{.items[0].metadata.name}' || true)

if [[ -z "$POD_NAME" ]]; then
  echo "ERROR: Elasticsearch pod not found" >&2
  exit 1
fi

echo ">> Running enrollment token command on pod: $POD_NAME" >&2
TOKEN=$(kubectl exec -n default "$POD_NAME" \
          -- bin/elasticsearch-create-enrollment-token -s kibana || true)

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Failed to get enrollment token" >&2
  exit 1
fi

# strip line breaks and emit pure JSON on stdout
TOKEN_CLEANED=$(echo "$TOKEN" | tr -d '\r\n')
echo "{\"result\": \"$TOKEN_CLEANED\"}"
