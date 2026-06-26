# Kind Upgrade And Deployment Strategy Lab

This lab is separate from the AWS BFSI project. It teaches:

- Rolling deployments.
- Blue-green deployments.
- Canary deployments.
- Control-plane upgrade planning.
- Data-plane worker maintenance and drain practice.
- Common deployment and upgrade failures.
- Patching playbooks for apps, databases, Python, OS, Kubernetes add-ons, and tooling.

## Important Kind Note

kind is excellent for learning Kubernetes behavior locally, but it is not a production cluster lifecycle manager. In production kubeadm clusters, you normally upgrade the control plane first and then worker nodes. In EKS, AWS upgrades the highly available control plane and then you upgrade the data plane nodes.

In this lab:

- Control-plane upgrade is practiced as a **blue-green cluster replacement**: create a new kind cluster with the newer node image, deploy and test workloads there, then switch traffic/context.
- Data-plane upgrade is practiced as **worker maintenance**: cordon, drain, observe pod movement, simulate patching, then uncordon.

This gives you the same operational thinking used in real upgrades without pretending kind is EKS or kubeadm.

## Folder Map

- `configs/`: 2-node kind cluster config.
- `manifests/`: rolling, blue-green, and canary Kubernetes manifests.
- `failures/`: broken manifests and failure drills.
- `scripts/`: PowerShell scripts for Windows learners.
- `docs/`: learning notes, upgrade playbooks, and troubleshooting.

## Prerequisites

Install:

- Docker Desktop
- kind
- kubectl

Check:

```powershell
cd C:\Users\shekk\Documents\mine-aws-terraform\kind-upgrade-lab
.\scripts\00-preflight.ps1
```

## Quick Start

Create a 2-node kind cluster:

```powershell
.\scripts\01-create-kind-cluster.ps1
```

Deploy the rolling demo v1:

```powershell
.\scripts\02-deploy-rolling-v1.ps1
```

In another PowerShell window, test using port-forward:

```powershell
kubectl port-forward svc/payments-rolling 8080:80 -n rollout-lab
```

Open:

```text
http://localhost:8080
```

Run a rolling update:

```powershell
.\scripts\03-rolling-update.ps1
```

Run blue-green:

```powershell
.\scripts\04-blue-green.ps1
```

Run canary:

```powershell
.\scripts\05-canary.ps1 -StableReplicas 4 -CanaryReplicas 1
```

Simulate data-plane worker patching:

```powershell
.\scripts\06-simulate-data-plane-upgrade.ps1
```

Practice control-plane replacement:

```powershell
.\scripts\07-control-plane-upgrade-bluegreen.ps1 -NewNodeImage kindest/node:v1.35.0
```

Clean up:

```powershell
.\scripts\08-cleanup.ps1
```

## Learning Order

For exact command-by-command execution, use `STEP_BY_STEP.md`.

1. Read `docs/deployment-strategies.md`.
2. Run rolling update.
3. Run blue-green switch.
4. Run canary scaling.
5. Read `docs/control-plane-data-plane-upgrades-kind.md`.
6. Run data-plane drain simulation.
7. Run control-plane blue-green cluster replacement.
8. Practice the failures in `failures/README.md`.
9. Read `docs/patching-upgrade-playbook.md`.

## Interview Pitch

I created a local Kubernetes upgrade and rollout lab using kind. The cluster has one control-plane node and one worker node. I practiced rolling updates, blue-green switching, and canary rollout using Kubernetes Deployments and Services. For data-plane patching, I cordoned and drained the worker node, verified pod rescheduling, and uncordoned it after maintenance. Since kind is not a production upgrade manager, I practiced control-plane upgrades using a blue-green cluster replacement model with a newer kind node image. I also documented realistic failures such as ImagePullBackOff, readiness probe failures, PDB blocking drain, service selector mistakes, and rollback steps.
