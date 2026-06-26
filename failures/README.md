# Failure Drills

Run these after creating the cluster.

## 1. ImagePullBackOff During Deployment

Inject:

```powershell
kubectl apply -f .\failures\bad-image.yaml
kubectl rollout status deployment/payments-bad-image -n rollout-lab
```

Observe:

```powershell
kubectl get pods -n rollout-lab
kubectl describe pod -n rollout-lab -l app=payments-bad-image
kubectl get events -n rollout-lab --sort-by=.lastTimestamp
```

Recover:

```powershell
kubectl delete -f .\failures\bad-image.yaml
```

Interview point:

- The pod never starts because the image cannot be pulled.
- Check image name, tag, registry credentials, node egress, and image pull policy.

## 2. Readiness Probe Failure

Inject:

```powershell
kubectl apply -f .\failures\bad-readiness.yaml
kubectl get pods -n rollout-lab
kubectl get endpoints payments-bad-readiness -n rollout-lab
```

Observe:

```powershell
kubectl describe pod -n rollout-lab -l app=payments-bad-readiness
kubectl describe svc payments-bad-readiness -n rollout-lab
```

Recover:

```powershell
kubectl delete -f .\failures\bad-readiness.yaml
```

Interview point:

- Pods can be running but not ready.
- A Service only sends traffic to ready endpoints.

## 3. Service Selector Mistake

Inject:

```powershell
kubectl apply -f .\failures\bad-service-selector.yaml
kubectl get svc,endpoints -n rollout-lab
```

Recover:

```powershell
kubectl delete -f .\failures\bad-service-selector.yaml
```

Interview point:

- The app is healthy, but the Service has no endpoints because labels do not match selectors.

## 4. PDB Blocks Worker Drain

Inject:

```powershell
kubectl apply -f .\failures\pdb-blocks-drain.yaml
kubectl rollout status deployment/payments-pdb-block -n rollout-lab
```

Try:

```powershell
kubectl drain kind-upgrade-lab-worker --ignore-daemonsets --delete-emptydir-data --force --timeout=60s
```

Recover:

```powershell
kubectl uncordon kind-upgrade-lab-worker
kubectl delete -f .\failures\pdb-blocks-drain.yaml
```

Interview point:

- PDB protects availability, but an overly strict PDB can block node upgrades.
- Fix by increasing replicas, relaxing PDB temporarily, or adding capacity.

## 5. Canary Sends Some Users To Bad Version

Inject:

```powershell
kubectl apply -f .\manifests\canary\canary.yaml
kubectl apply -f .\failures\bad-canary.yaml
kubectl scale deploy/payments-stable -n rollout-lab --replicas=4
kubectl scale deploy/payments-canary -n rollout-lab --replicas=1
```

Observe:

```powershell
kubectl port-forward svc/payments-canary 8081:80 -n rollout-lab
```

Call `http://localhost:8081` many times. Some responses may fail or show bad canary behavior depending on the injected issue.

Recover:

```powershell
kubectl scale deploy/payments-canary -n rollout-lab --replicas=0
```

Interview point:

- Canary reduces blast radius, but you still need metrics and rollback gates.
