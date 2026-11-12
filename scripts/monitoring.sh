#!/usr/bin/env bash
set -euo pipefail
kubectl --context kind-cicd-lab apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Kind uses self-signed kubelet certificates; classroom-only exception.
kubectl --context kind-cicd-lab -n kube-system patch deployment metrics-server --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl --context kind-cicd-lab -n kube-system rollout status deployment/metrics-server --timeout=180s
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --kube-context kind-cicd-lab -n monitoring --create-namespace --wait --timeout 10m
kubectl --context kind-cicd-lab top nodes
kubectl --context kind-cicd-lab top pods -n cicd-lab
