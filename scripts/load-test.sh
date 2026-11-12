#!/usr/bin/env bash
set -euo pipefail
kubectl --context kind-cicd-lab -n cicd-lab get pod load-generator >/dev/null 2>&1 && { echo "Existing load-generator found; inspect it first."; exit 1; }
trap 'kubectl --context kind-cicd-lab -n cicd-lab delete pod load-generator --ignore-not-found' EXIT
kubectl --context kind-cicd-lab -n cicd-lab run load-generator --image=busybox:1.36 --restart=Never -- /bin/sh -c 'for i in 1 2 3 4 5 6 7 8; do (while true; do wget -q -O /dev/null http://cloud-admin-web-service; done) & done; wait'
for i in $(seq 1 30); do
  date -u
  kubectl --context kind-cicd-lab -n cicd-lab get hpa,pods
  sleep 10
done
