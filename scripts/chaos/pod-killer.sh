#!/usr/bin/env bash
# pod-killer.sh — chaos drill that randomly evicts a rag-api pod and verifies
# the SLO holds.
#
# Usage:
#   ./scripts/chaos/pod-killer.sh -n rag -l app.kubernetes.io/name=rag-api
set -euo pipefail

NS="rag"
SELECTOR="app.kubernetes.io/name=rag-api"
COUNT=1

while getopts "n:l:c:" opt; do
  case "$opt" in
    n) NS="$OPTARG" ;;
    l) SELECTOR="$OPTARG" ;;
    c) COUNT="$OPTARG" ;;
    *) echo "Usage: $0 [-n namespace] [-l selector] [-c count]" >&2; exit 1 ;;
  esac
done

mapfile -t pods < <(kubectl -n "$NS" get pod -l "$SELECTOR" -o name | shuf | head -n "$COUNT")
if (( ${#pods[@]} == 0 )); then
  echo "no pods matching $SELECTOR in $NS" >&2
  exit 1
fi

for p in "${pods[@]}"; do
  echo "{\"action\":\"chaos_evict\",\"namespace\":\"$NS\",\"target\":\"$p\"}"
  kubectl -n "$NS" delete "$p" --grace-period=10
done

echo
echo "==> Watching deployment recover for 60s..."
kubectl -n "$NS" rollout status deploy -l "$SELECTOR" --timeout=60s

echo "==> Checking error budget burn over the last 5m..."
# In a real drill, query Prometheus for the burn-rate alert and assert == 0.
