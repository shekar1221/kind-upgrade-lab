# Troubleshooting Guide

## Deployment Stuck

Check:

```powershell
kubectl rollout status deployment/payments-rolling -n rollout-lab
kubectl describe deployment payments-rolling -n rollout-lab
kubectl get rs,pods -n rollout-lab -o wide
kubectl get events -n rollout-lab --sort-by=.lastTimestamp
```

Common causes:

- ImagePullBackOff.
- Readiness probe failing.
- Not enough CPU or memory.
- Bad command or args.

## Pod CrashLoopBackOff

Check:

```powershell
kubectl logs POD_NAME -n rollout-lab --previous
kubectl describe pod POD_NAME -n rollout-lab
```

Common causes:

- App exits immediately.
- Missing config.
- Liveness probe too aggressive.
- Runtime dependency missing.

## Service Has No Endpoints

Check:

```powershell
kubectl get svc,endpoints -n rollout-lab
kubectl get pods -n rollout-lab --show-labels
kubectl describe svc SERVICE_NAME -n rollout-lab
```

Common causes:

- Service selector label mismatch.
- Pods are not ready.

## Drain Fails

Check:

```powershell
kubectl get pdb -A
kubectl describe node kind-upgrade-lab-worker
kubectl get pods -A -o wide
```

Common causes:

- PDB blocks eviction.
- Single replica app.
- No capacity on remaining nodes.
- Pod uses local storage.
- DaemonSet pods are ignored but still visible.

Fix:

- Add replicas.
- Add capacity.
- Relax PDB temporarily with approval.
- Use `--delete-emptydir-data` when acceptable.

## Control-Plane Replacement Fails

Check:

```powershell
kind get clusters
docker ps
docker logs kind-upgrade-lab-green-control-plane
kind export logs --name kind-upgrade-lab-green .\kind-logs
```

Common causes:

- Docker Desktop not running.
- Wrong kind node image tag.
- Not enough local CPU or memory.
- Port conflict if you added port mappings.

## Rollback Commands

Rolling rollback:

```powershell
kubectl rollout undo deployment/payments-rolling -n rollout-lab
```

Blue-green rollback:

```powershell
.\scripts\04-blue-green.ps1 -Target blue
```

Canary rollback:

```powershell
kubectl scale deployment/payments-canary -n rollout-lab --replicas=0
```

Node maintenance rollback:

```powershell
kubectl uncordon kind-upgrade-lab-worker
```
