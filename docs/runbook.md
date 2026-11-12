# Execution and evidence runbook

## Current verification status
Implementation prepared November 8, 2026. VM deployment, registry publishing, monitoring dashboards, autoscaling and rollback are NOT verified until their actual runs are captured. GitHub CI uses a disposable Kind cluster; that does not replace the required course VM evidence.

## Prerequisites and access
Sign into the Ohio Cyber Range portal and open dev-vm and client-vm. Never share passwords in repository files. On dev-vm, authenticate GitHub using the normal SSH-key or GitHub CLI flow, then clone the private repository. Each teammate must make their own commit and review; these must not be impersonated. Instructor collaborator access requires the instructor's exact GitHub username.

## Integration and release
Review this implementation PR into develop after CI passes. Promote develop to main through a separate PR after review. A main push validates the app and disposable Kubernetes deployment, then publishes immutable commit and latest tags to GHCR.

## VM2 deployment
Use the existing cicd-lab Kind cluster. For a new cluster only:
```bash
kind create cluster --name cicd-lab --config kind-config.yaml
```
Register the GitHub-generated Linux x64 self-hosted runner on VM2 using Settings > Actions > Runners. Use its current generated commands; do not commit registration tokens. The runner user needs Docker access and the kind-cicd-lab kubeconfig. Run as a service using the generated runner instructions. Never run untrusted PR jobs on this VM. CD only executes after successful trusted main pushes and checks out the exact tested commit.

CD pulls the private GHCR image using the job token, loads it into Kind and deploys the immutable commit tag. Temporary registry credentials are removed after the step. To deploy manually, authenticate Docker to GHCR first:
```bash
IMAGE=ghcr.io/itsme7318/cloud-admin-cicd-lab:COMMIT_SHA
docker pull "$IMAGE"
kind load docker-image "$IMAGE" --name cicd-lab
bash scripts/deploy-kind.sh "$IMAGE"
```
Replace COMMIT_SHA with an actual successful published commit. The Kind mapping in this repository binds localhost. For remote browsing use an SSH tunnel; an existing cluster may retain its original mapping.

## Monitoring
```bash
bash scripts/monitoring.sh
kubectl --context kind-cicd-lab top nodes
kubectl --context kind-cicd-lab top pods -n cicd-lab
kubectl --context kind-cicd-lab -n monitoring port-forward svc/monitoring-grafana 3000:80
```
In a separate VM terminal obtain the generated Grafana admin password from the monitoring-grafana secret; keep it out of screenshots and reports. Open localhost:3000 on the VM or forward it with SSH. Capture CPU, memory and pod dashboards. The metrics-server insecure kubelet TLS flag is a Kind classroom exception, not an enterprise setting.

## Autoscaling
```bash
bash scripts/load-test.sh | tee hpa-load.txt
kubectl --context kind-cicd-lab -n cicd-lab get hpa,pods -w
```
The workload stops after five minutes. Watch scale-in after load stops; use Ctrl+C to stop watching. Record timestamps, actual CPU and replica counts. If load is insufficient, investigate metrics and load before changing targets; do not claim scale-out without observing it.

## Rolling update and rollback
Publish a real second version through a reviewed PR and successful main CI/CD. Capture rollout status and history before rolling back:
```bash
kubectl --context kind-cicd-lab -n cicd-lab rollout history deployment/cloud-admin-web
kubectl --context kind-cicd-lab -n cicd-lab rollout undo deployment/cloud-admin-web
kubectl --context kind-cicd-lab -n cicd-lab rollout status deployment/cloud-admin-web --timeout=180s
curl -f http://localhost:8080/
```
Confirm the prior version is served. Resume the desired release through CD afterward. A rollback requires at least two real deployment revisions.

## Manual scaling
For the demonstration, first save and temporarily remove this project's HPA so it cannot fight manual replica changes:
```bash
kubectl --context kind-cicd-lab -n cicd-lab delete hpa cloud-admin-web-hpa
kubectl --context kind-cicd-lab -n cicd-lab scale deployment/cloud-admin-web --replicas=4
kubectl --context kind-cicd-lab -n cicd-lab rollout status deployment/cloud-admin-web --timeout=180s
kubectl --context kind-cicd-lab -n cicd-lab get pods
kubectl --context kind-cicd-lab -n cicd-lab scale deployment/cloud-admin-web --replicas=2
kubectl --context kind-cicd-lab apply -f k8s/hpa.yaml
```

## Required submission evidence
- Phase I: original Docker and CLI installation screenshots, repository URL, authentic teammate contributions.
- Phase II: commit/push screenshot, successful CI and CD links, GHCR image, deployed page and health endpoint.
- Phase III: manifests, pod/ReplicaSet/service outputs, rolling update, rollback and manual scaling.
- Phase IV: metrics-server output, Grafana dashboards, HPA scale-out and scale-in observations with analysis.
- Part I: existing planning report and budget.
- Part III: 5–10 minute presentation and the team's recorded reflection based on actual results.

Upload only to the matching Canvas assignment after verifying its title, phase and required files. Do not submit this runbook as fabricated execution evidence.
