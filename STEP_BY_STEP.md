# Kind Upgrade Lab: Step By Step

Use this guide exactly in order. Do not run all commands at once. Run one step, observe the result, then continue.

## 0. Open PowerShell In The Lab Folder

```powershell
cd C:\Users\shekk\Documents\mine-aws-terraform\kind-upgrade-lab
```

## 1. Start Docker Desktop

Open Docker Desktop manually and wait until it says the engine is running.

Then check:

```powershell
docker info
```

Expected:

- Docker server details are printed.
- No error about Docker daemon not running.

## 2. Run Preflight

```powershell
.\scripts\00-preflight.ps1
```

Expected:

- Docker found.
- kind found.
- kubectl found.
- Docker daemon running.

If kind is missing:

```powershell
winget install Kubernetes.kind
```

If kubectl is missing:

```powershell
winget install Kubernetes.kubectl
```

## 3. Create A 2-Node Kind Cluster

For a real upgrade practice, create the first cluster with an older Kubernetes node image.

```powershell
.\scripts\01-create-kind-cluster.ps1 -NodeImage kindest/node:v1.34.3
```

Expected:

```text
kind-upgrade-lab-control-plane
kind-upgrade-lab-worker
```

Check:

```powershell
kubectl get nodes -o wide
kubectl cluster-info
```

What to explain:

- Control plane node runs the Kubernetes API and cluster control components.
- Worker node runs application pods.
- In kind, both nodes are Docker containers.

## 4. Deploy Rolling Version 1

```powershell
.\scripts\02-deploy-rolling-v1.ps1
```

Expected:

- Namespace `rollout-lab` created.
- Deployment `payments-rolling` created.
- Service `payments-rolling` created.
- Two pods become `Running`.

Check:

```powershell
kubectl get all -n rollout-lab
kubectl get pods -n rollout-lab -o wide
kubectl rollout status deployment/payments-rolling -n rollout-lab
```

## 5. Test Rolling Version 1

Open a second PowerShell window:

```powershell
cd C:\Users\shekk\Documents\mine-aws-terraform\kind-upgrade-lab
kubectl port-forward svc/payments-rolling 8080:80 -n rollout-lab
```

Open browser:

```text
http://localhost:8080
```

Or test from PowerShell:

```powershell
Invoke-WebRequest http://localhost:8080
```

Expected response:

```text
payments-api rolling v1
```

Keep or stop the port-forward. To stop it, press `Ctrl+C` in that PowerShell window.

## 6. Perform Rolling Update To Version 2

```powershell
.\scripts\03-rolling-update.ps1
```

Watch:

```powershell
kubectl get pods -n rollout-lab -w
```

Expected:

- New v2 pods are created.
- Old v1 pods are removed only after new pods are ready.
- Deployment completes successfully.

Check rollout history:

```powershell
kubectl rollout history deployment/payments-rolling -n rollout-lab
kubectl get rs,pods -n rollout-lab -l app=payments-rolling -o wide
```

Test again:

```powershell
kubectl port-forward svc/payments-rolling 8080:80 -n rollout-lab
Invoke-WebRequest http://localhost:8080
```

Expected response:

```text
payments-api rolling v2
```

Rollback command:

```powershell
kubectl rollout undo deployment/payments-rolling -n rollout-lab
```

What to explain:

- Rolling update changes the same Deployment gradually.
- `maxSurge=1` allows one extra pod during update.
- `maxUnavailable=0` protects availability.

## 7. Deploy Blue-Green

```powershell
.\scripts\04-blue-green.ps1 -Target blue
```

Expected:

- Blue deployment exists.
- Green deployment exists.
- Service `payments-bg` points to blue.

Check:

```powershell
kubectl get deploy,pods,svc,endpoints -n rollout-lab
kubectl get pods -n rollout-lab -l app=payments-bg --show-labels
kubectl get svc payments-bg -n rollout-lab -o yaml
```

Test blue:

```powershell
kubectl port-forward svc/payments-bg 8082:80 -n rollout-lab
Invoke-WebRequest http://localhost:8082
```

Expected:

```text
payments-api BLUE active
```

## 8. Switch Blue-Green Traffic To Green

Stop the previous port-forward if needed with `Ctrl+C`.

Run:

```powershell
.\scripts\04-blue-green.ps1 -Target green
```

Test:

```powershell
kubectl port-forward svc/payments-bg 8082:80 -n rollout-lab
Invoke-WebRequest http://localhost:8082
```

Expected:

```text
payments-api GREEN candidate
```

Rollback to blue:

```powershell
.\scripts\04-blue-green.ps1 -Target blue
```

What to explain:

- Blue and green run at the same time.
- Service selector controls which version gets traffic.
- Rollback is fast because old blue pods are still running.

## 9. Deploy Canary

```powershell
.\scripts\05-canary.ps1 -StableReplicas 4 -CanaryReplicas 1
```

Expected:

- Four stable pods.
- One canary pod.
- Service `payments-canary` selects both stable and canary pods.
- Approximate canary traffic is 20 percent by pod count.

Check:

```powershell
kubectl get pods -n rollout-lab -l app=payments-canary --show-labels
kubectl get endpoints payments-canary -n rollout-lab
```

Test several times:

```powershell
kubectl port-forward svc/payments-canary 8083:80 -n rollout-lab
```

In another PowerShell window:

```powershell
1..20 | ForEach-Object { (Invoke-WebRequest http://localhost:8083).Content }
```

Expected:

- Most responses say `payments-api stable`.
- Some responses say `payments-api canary`.

Increase canary:

```powershell
.\scripts\05-canary.ps1 -StableReplicas 3 -CanaryReplicas 2
```

Promote canary:

```powershell
.\scripts\05-canary.ps1 -StableReplicas 0 -CanaryReplicas 5
```

Rollback canary:

```powershell
kubectl scale deployment/payments-canary -n rollout-lab --replicas=0
```

What to explain:

- Canary reduces blast radius.
- You send only a small percentage of traffic to the new version.
- In production, canary should be controlled by metrics, ingress, or service mesh.

## 10. Practice Failure 1: Bad Image

```powershell
kubectl apply -f .\failures\bad-image.yaml
kubectl get pods -n rollout-lab
kubectl describe pod -n rollout-lab -l app=payments-bad-image
kubectl get events -n rollout-lab --sort-by=.lastTimestamp
```

Expected:

- Pod shows `ImagePullBackOff` or `ErrImagePull`.

Recover:

```powershell
kubectl delete -f .\failures\bad-image.yaml
```

What to explain:

- Wrong image name or tag prevents pod startup.
- Check registry, image tag, imagePullSecret, and node egress.

## 11. Practice Failure 2: Readiness Probe Failing

```powershell
kubectl apply -f .\failures\bad-readiness.yaml
kubectl get pods -n rollout-lab
kubectl get endpoints payments-bad-readiness -n rollout-lab
kubectl describe pod -n rollout-lab -l app=payments-bad-readiness
```

Expected:

- Pod may be running but not ready.
- Service endpoint is empty or not usable.

Recover:

```powershell
kubectl delete -f .\failures\bad-readiness.yaml
```

What to explain:

- Running is not the same as ready.
- Service traffic goes only to ready endpoints.

## 12. Practice Failure 3: Service Selector Wrong

```powershell
kubectl apply -f .\failures\bad-service-selector.yaml
kubectl get pods -n rollout-lab --show-labels
kubectl get svc,endpoints -n rollout-lab
kubectl describe svc payments-bad-selector -n rollout-lab
```

Expected:

- Pod is healthy.
- Service has no endpoints.

Recover:

```powershell
kubectl delete -f .\failures\bad-service-selector.yaml
```

What to explain:

- Service selector must match pod labels.
- If selector is wrong, traffic never reaches pods.

## 13. Practice Failure 4: PDB Blocks Drain

```powershell
kubectl apply -f .\failures\pdb-blocks-drain.yaml
kubectl rollout status deployment/payments-pdb-block -n rollout-lab
kubectl get pdb -n rollout-lab
```

Try draining worker:

```powershell
kubectl drain kind-upgrade-lab-worker --ignore-daemonsets --delete-emptydir-data --force --timeout=60s
```

Expected:

- Drain may fail because PDB requires one pod available and there is only one replica.

Recover:

```powershell
kubectl uncordon kind-upgrade-lab-worker
kubectl delete -f .\failures\pdb-blocks-drain.yaml
```

What to explain:

- PDB protects availability.
- A strict PDB can block node maintenance.
- Fix by adding replicas, adding capacity, or relaxing PDB with approval.

## 14. Simulate Data-Plane Upgrade

Data plane means worker nodes.

Run:

```powershell
.\scripts\06-simulate-data-plane-upgrade.ps1
```

Expected:

- Worker node is cordoned.
- Pods are drained from the worker.
- Script waits to simulate patching.
- Worker node is uncordoned.

Useful checks:

```powershell
kubectl get nodes
kubectl get pods -A -o wide
kubectl describe node kind-upgrade-lab-worker
```

What to explain:

- Cordon stops new pods from scheduling to the node.
- Drain evicts existing pods.
- PDBs and replica count decide whether drain is safe.
- Uncordon returns the node to scheduling.

## 15. Practice Control-Plane Upgrade With Blue-Green Cluster Replacement

kind does not upgrade an existing cluster like production kubeadm or EKS. For kind, practice control-plane upgrade as a replacement cluster.

Create replacement cluster with a newer image:

```powershell
.\scripts\07-control-plane-upgrade-bluegreen.ps1 -NewNodeImage kindest/node:v1.35.1
```

Expected:

- New cluster `kind-upgrade-lab-green` is created.
- kubectl context changes to `kind-kind-upgrade-lab-green`.
- Workload is deployed on the replacement cluster.

Check:

```powershell
kind get clusters
kubectl config get-contexts
kubectl get nodes -o wide
kubectl get pods -n rollout-lab -o wide
```

Switch back to old cluster:

```powershell
kubectl config use-context kind-kind-upgrade-lab
kubectl get nodes -o wide
```

Switch to new cluster:

```powershell
kubectl config use-context kind-kind-upgrade-lab-green
kubectl get nodes -o wide
```

What to explain:

- In real EKS, AWS upgrades the control plane.
- In real kubeadm, you upgrade control-plane nodes first.
- In kind, clusters are disposable, so replacement is the clean learning pattern.

## 16. Export Logs If Something Fails

```powershell
.\scripts\09-export-logs.ps1
```

Expected:

- Logs are exported to `kind-logs`.

Use this when:

- Cluster creation fails.
- Pods are stuck.
- Control-plane replacement fails.

## 17. Cleanup Everything

```powershell
.\scripts\08-cleanup.ps1
```

Expected:

- `kind-upgrade-lab` cluster deleted.
- `kind-upgrade-lab-green` cluster deleted if it exists.

Verify:

```powershell
kind get clusters
docker ps
```

## 18. Interview Order To Explain

Use this order:

1. I created a 2-node kind cluster.
2. I deployed version 1 using rolling strategy.
3. I upgraded to version 2 with zero unavailable pods.
4. I practiced blue-green by switching the Service selector.
5. I practiced canary by changing stable and canary replica counts.
6. I injected failures: bad image, readiness failure, wrong service selector, and PDB blocking drain.
7. I simulated data-plane patching using cordon, drain, and uncordon.
8. I practiced control-plane upgrade as blue-green cluster replacement because kind clusters are disposable.
9. I documented rollback and cleanup.

## 19. Key Commands To Memorize

```powershell
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.lastTimestamp
kubectl rollout status deployment/DEPLOYMENT_NAME -n NAMESPACE
kubectl rollout history deployment/DEPLOYMENT_NAME -n NAMESPACE
kubectl rollout undo deployment/DEPLOYMENT_NAME -n NAMESPACE
kubectl get svc,endpoints -n NAMESPACE
kubectl describe pod POD_NAME -n NAMESPACE
kubectl logs POD_NAME -n NAMESPACE --previous
kubectl cordon NODE_NAME
kubectl drain NODE_NAME --ignore-daemonsets --delete-emptydir-data --force
kubectl uncordon NODE_NAME
```
