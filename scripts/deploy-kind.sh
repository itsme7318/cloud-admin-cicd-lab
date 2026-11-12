#!/usr/bin/env bash
set -euo pipefail
image="${1:?Usage: deploy-kind.sh IMAGE}"
[[ "$image" =~ ^[a-zA-Z0-9./:_@-]+$ ]] || exit 2
kubectl --context kind-cicd-lab get nodes
kubectl --context kind-cicd-lab apply -f k8s/namespace.yaml
for file in configmap secret service; do
  kubectl --context kind-cicd-lab apply -f "k8s/$file.yaml"
done
# Render desired immutable image before apply, avoiding a broken initial rollout.
kubectl patch --local -f k8s/deployment.yaml --type=strategic \
  -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"web\",\"image\":\"$image\"}]}}}}" -o yaml |
  kubectl --context kind-cicd-lab apply -f -
kubectl --context kind-cicd-lab apply -f k8s/hpa.yaml
kubectl --context kind-cicd-lab -n cicd-lab rollout status deployment/cloud-admin-web --timeout=180s
curl --fail --retry 12 --retry-connrefused --retry-delay 2 http://localhost:8080/
test "$(curl --fail --silent http://localhost:8080/health.html)" = OK
kubectl --context kind-cicd-lab -n cicd-lab get pods,rs,svc,hpa -o wide
