#!/usr/bin/env bash
# bootstrap-cluster.sh — bring a freshly-Terraform'd cluster online with FluxCD.
#
# Usage:
#   ENV=dev CLUSTER=dev-eks ./scripts/bootstrap-cluster.sh
set -euo pipefail

ENV="${ENV:?set ENV (dev|staging|prod)}"
CLUSTER="${CLUSTER:?set CLUSTER (dev-eks|staging-gke|prod-aks)}"
REPO_URL="${REPO_URL:-ssh://git@github.com/nawex/devops-ai-ml-infrastructure}"

echo "==> Checking kubectl context"
kubectl config current-context >/dev/null

echo "==> Checking that flux CLI is installed"
flux --version >/dev/null

echo "==> Pre-flight: cluster reachable"
kubectl get ns >/dev/null

echo "==> Bootstrapping FluxCD against ${CLUSTER}"
flux bootstrap git \
  --url="${REPO_URL}" \
  --branch=main \
  --path="flux/clusters/${CLUSTER}" \
  --components-extra=image-reflector-controller,image-automation-controller

echo "==> Waiting for first reconciliation..."
flux reconcile source git flux-system
flux reconcile kustomization flux-system

echo "==> Status"
flux get kustomizations -A
echo
echo "✅ Cluster ${CLUSTER} (env=${ENV}) bootstrapped."
