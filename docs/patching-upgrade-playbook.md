# Patching And Upgrade Playbook

Use this as a general checklist for application, database, Python, OS, Kubernetes, and tool upgrades.

## Universal Upgrade Flow

1. Identify current version and target version.
2. Read release notes and breaking changes.
3. Check compatibility matrix.
4. Take backup or confirm rollback path.
5. Test in dev.
6. Run smoke tests.
7. Deploy using rolling, blue-green, or canary.
8. Monitor errors, latency, restarts, and resource usage.
9. Keep rollback ready until stable.
10. Document issue and prevention.

## Application Upgrade

Examples:

- Spring Boot 3.3 to 3.4.
- API v1 to API v2.
- New container image.

Checklist:

- Build immutable image tag.
- Run unit tests and integration tests.
- Check config and secrets.
- Verify readiness and liveness probes.
- Confirm DB schema compatibility.
- Deploy canary first for risky changes.

Commands:

```powershell
kubectl set image deployment/payments-rolling http-echo=hashicorp/http-echo:1.0 -n rollout-lab
kubectl rollout status deployment/payments-rolling -n rollout-lab
kubectl rollout undo deployment/payments-rolling -n rollout-lab
```

Interview point:

Application patching is not only changing an image. You also validate config, health checks, metrics, database compatibility, and rollback.

## Database Upgrade

Examples:

- PostgreSQL minor version patch.
- Schema migration.
- Index change.

Safe schema pattern:

1. Expand: add new nullable column or new table.
2. Deploy app that can use old and new schema.
3. Backfill data.
4. Switch reads/writes.
5. Contract: remove old column later.

Checklist:

- Take backup.
- Test restore.
- Run migration in staging.
- Check long-running locks.
- Check replication lag if replicas exist.
- Keep old app compatible until migration is complete.

Commands to practice:

```powershell
kubectl exec -n bfsi-payments statefulset/postgres -- sh -c "PGPASSWORD=`$POSTGRES_PASSWORD psql -U `$POSTGRES_USER -d payments -c `"select version();`""
kubectl exec -n bfsi-payments statefulset/postgres -- sh -c "PGPASSWORD=`$POSTGRES_PASSWORD psql -U `$POSTGRES_USER -d payments -c `"select state, count(*) from pg_stat_activity group by state;`""
```

Interview point:

Database changes are often the highest-risk part of application deployment. Use backward-compatible migrations and tested rollback.

## Python Runtime Upgrade

Examples:

- Python 3.10 to 3.11.
- Python 3.11 to 3.12.
- Library CVE patch.

Checklist:

- Update base image, for example `python:3.11-slim` to `python:3.12-slim`.
- Rebuild virtual environment.
- Pin dependencies.
- Run tests.
- Scan for CVEs.
- Deploy canary.
- Watch CPU and memory because runtime behavior can change.

Dockerfile example:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Interview point:

Runtime upgrades can break dependencies even when application code is unchanged.

## OS And Node Patching

Examples:

- Linux security patch.
- Kernel patch.
- Container runtime patch.
- AMI update in EKS managed node group.

Safe flow:

1. Add capacity if needed.
2. Cordon node.
3. Drain node.
4. Patch or replace node.
5. Validate node ready.
6. Uncordon node.
7. Repeat one node at a time.

Practice:

```powershell
.\scripts\06-simulate-data-plane-upgrade.ps1
```

Interview point:

Node patching is safe only if applications have replicas, PDBs are correct, and there is enough spare capacity.

## Kubernetes Add-On Patching

Examples:

- CoreDNS.
- kube-proxy.
- CNI plugin.
- Ingress controller.
- CSI driver.
- Metrics server.
- Prometheus stack.

Checklist:

- Check supported Kubernetes versions.
- Upgrade one add-on at a time.
- Watch pods in `kube-system`.
- Verify DNS, networking, ingress, storage, and metrics after each upgrade.

Commands:

```powershell
kubectl get pods -n kube-system -o wide
kubectl rollout status deployment/coredns -n kube-system
kubectl get events -n kube-system --sort-by=.lastTimestamp
```

Interview point:

Application failures after cluster upgrade are often caused by add-on incompatibility, not the app itself.

## Helm Chart Upgrade

Flow:

```bash
helm repo update
helm diff upgrade RELEASE CHART -n NAMESPACE -f values.yaml
helm upgrade RELEASE CHART -n NAMESPACE -f values.yaml
helm rollback RELEASE REVISION -n NAMESPACE
```

Checklist:

- Save current values.
- Check chart release notes.
- Use `helm diff` when available.
- Upgrade in lower environment first.
- Roll back if probes or metrics fail.

## Terraform Provider Or Module Upgrade

Flow:

```powershell
terraform init -upgrade
terraform fmt -recursive
terraform validate
terraform plan
```

Checklist:

- Read provider upgrade guide.
- Commit lock file update intentionally.
- Review plan carefully.
- Avoid changing provider and infrastructure logic in the same PR when possible.

## Certificate And Secret Rotation

Checklist:

- Check expiry date.
- Create new secret before switching.
- Reload or restart workloads safely.
- Validate TLS handshake.
- Remove old secret after stable period.

Commands:

```powershell
kubectl get secrets -A
kubectl describe secret SECRET_NAME -n NAMESPACE
```

## Choosing Strategy By Patch Type

Application image:

- Rolling for low risk.
- Canary for medium/high risk.
- Blue-green for fast rollback.

Database schema:

- Expand-contract.
- Avoid immediate destructive changes.

Node OS patch:

- Drain one node at a time.

Control plane:

- Managed service upgrade or blue-green cluster replacement.

Python/runtime:

- Canary because behavior and dependencies can change.
