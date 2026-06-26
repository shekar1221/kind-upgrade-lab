# Deployment Strategies

## Rolling Deployment

Rolling deployment updates pods gradually in the same Deployment.

This lab uses:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

Meaning:

- Kubernetes can create one extra pod during update.
- Kubernetes should not take any old pod down until a new pod is ready.
- This is safest for normal low-risk releases.

Run:

```powershell
.\scripts\02-deploy-rolling-v1.ps1
.\scripts\03-rolling-update.ps1
```

Useful commands:

```powershell
kubectl rollout status deployment/payments-rolling -n rollout-lab
kubectl rollout history deployment/payments-rolling -n rollout-lab
kubectl rollout undo deployment/payments-rolling -n rollout-lab
kubectl get rs,pods -n rollout-lab -l app=payments-rolling -o wide
```

When rolling can fail:

- New image cannot be pulled.
- Readiness probe fails.
- Resource requests cannot be scheduled.
- App starts but returns errors.
- DB migration is not backward compatible.

## Blue-Green Deployment

Blue-green keeps two full versions side by side.

- Blue: current production version.
- Green: new version.
- Service selector decides which version receives traffic.

Run:

```powershell
.\scripts\04-blue-green.ps1 -Target green
```

Rollback:

```powershell
.\scripts\04-blue-green.ps1 -Target blue
```

Useful commands:

```powershell
kubectl get svc payments-bg -n rollout-lab -o yaml
kubectl get endpoints payments-bg -n rollout-lab
kubectl get pods -n rollout-lab -l app=payments-bg --show-labels
```

When blue-green can fail:

- Green is not fully warmed up.
- DB schema is not compatible with both versions.
- Background consumers run twice if both blue and green are active.
- Service selector points to the wrong labels.

## Canary Deployment

Canary sends a small percentage of traffic to a new version.

In this simple lab, percentage is controlled by pod count:

- 4 stable pods + 1 canary pod = roughly 20 percent canary.
- 9 stable pods + 1 canary pod = roughly 10 percent canary.

Run:

```powershell
.\scripts\05-canary.ps1 -StableReplicas 4 -CanaryReplicas 1
```

Promote canary:

```powershell
.\scripts\05-canary.ps1 -StableReplicas 0 -CanaryReplicas 5
```

Rollback canary:

```powershell
kubectl scale deployment/payments-canary -n rollout-lab --replicas=0
```

When canary can fail:

- Metrics are not strong enough to detect errors.
- Session stickiness hides failures.
- Stateful consumers process duplicated work.
- Canary and stable use incompatible DB schema.

## Strategy Selection

Use rolling when:

- Change is low risk.
- Backward compatibility is confirmed.
- Fast rollback is acceptable.

Use blue-green when:

- You need fast traffic switch.
- You want to test a full new environment.
- You can afford duplicate capacity.

Use canary when:

- You want small blast radius.
- You have good metrics.
- You can stop or roll back quickly.
