#!/usr/bin/env bash
set -euo pipefail

kubeconfig="${KUBECONFIG:-${1:-}}"
if [[ -z "$kubeconfig" ]]; then
  echo "KUBECONFIG not set and no path provided" >&2
  exit 1
fi

if [[ ! -f "$kubeconfig" ]]; then
  echo "kubeconfig not found: $kubeconfig" >&2
  exit 1
fi

timeout_seconds="${TIMEOUT_SECONDS:-300}"
interval_seconds="${INTERVAL_SECONDS:-5}"

start_ts=$(date +%s)

while true; do
  if kubectl --kubeconfig "$kubeconfig" get --raw='/readyz' >/dev/null 2>&1; then
    echo "kube-apiserver is ready"
    exit 0
  fi

  now_ts=$(date +%s)
  elapsed=$((now_ts - start_ts))
  if (( elapsed >= timeout_seconds )); then
    echo "timed out after ${timeout_seconds}s waiting for kube-apiserver readiness" >&2
    exit 1
  fi

  sleep "$interval_seconds"
done
