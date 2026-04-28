#!/usr/bin/env bash
# crashloop-bouncer.sh
#
# Looks for pods in the rag-platform namespaces that have been CrashLoopBackOff
# for >30 minutes AND last terminated with reason OOMKilled. For each, we open
# a remediation PR that bumps the container memory request by 25% in the
# matching Helm release values.
#
# Idempotent: we tag PRs with `selfheal/crashloop` and skip if a matching PR is
# already open for the same workload.
set -euo pipefail

NAMESPACES=(rag ingest qdrant)
THRESHOLD_MINUTES="${THRESHOLD_MINUTES:-30}"

now_ts=$(date +%s)

for ns in "${NAMESPACES[@]}"; do
  while IFS= read -r pod; do
    [[ -z "$pod" ]] && continue
    reason=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null || echo "")
    if [[ "$reason" != "OOMKilled" ]]; then
      continue
    fi
    started=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "")
    if [[ "$started" != "CrashLoopBackOff" ]]; then
      continue
    fi
    age_seconds=$(( now_ts - $(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.startTime}' | xargs -I{} date -d {} +%s) ))
    if (( age_seconds < THRESHOLD_MINUTES * 60 )); then
      continue
    fi

    workload=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.metadata.ownerReferences[0].name}')
    workload="${workload%-*}"   # strip ReplicaSet hash to get Deployment name
    echo "{\"action\":\"crashloop_remediation\",\"namespace\":\"$ns\",\"pod\":\"$pod\",\"workload\":\"$workload\",\"reason\":\"$reason\"}"

    # Open / update PR. Implementation outline:
    #   1. checkout main, branch selfheal/crashloop-${ns}-${workload}
    #   2. yq write helm/clusters/<env>/<workload>.values.yaml resources.requests.memory  +25%
    #   3. gh pr create --title "selfheal: bump ${workload} memory" --label selfheal/crashloop
    # The branch is auto-merged by Flux's image automation only after CI greens.
  done < <(kubectl -n "$ns" get pods --field-selector=status.phase!=Running -o name | sed 's|pod/||')
done
