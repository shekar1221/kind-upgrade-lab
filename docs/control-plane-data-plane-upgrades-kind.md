# Control Plane And Data Plane Upgrade Notes

## What Is Control Plane

The Kubernetes control plane runs the brain of the cluster:

- kube-apiserver
- etcd
- kube-scheduler
- kube-controller-manager

In EKS, AWS manages the control plane.

In kubeadm, you upgrade control-plane nodes first.

In kind, the control-plane runs inside a Docker container.

## What Is Data Plane

The data plane runs your workloads:

- worker nodes
- kubelet
- container runtime
- CNI networking
- application pods

In EKS, data plane can be managed node groups, self-managed nodes, or Fargate.

## Real Upgrade Order

Typical safe order:

1. Read release notes and deprecated APIs.
2. Backup etcd or confirm managed backup responsibility.
3. Upgrade control plane.
4. Upgrade add-ons such as CoreDNS, kube-proxy, CNI, ingress controller, CSI drivers.
5. Upgrade worker nodes one at a time.
6. Verify applications.
7. Monitor errors, latency, restarts, and node health.

## Kind Lab Equivalent

kind does not behave like a production upgrade service. For learning, use two exercises.

### Exercise 1: Control-Plane Replacement

Create a new cluster with a newer node image:

```powershell
.\scripts\07-control-plane-upgrade-bluegreen.ps1 -NewNodeImage kindest/node:v1.35.0
```

What this teaches:

- Build a replacement cluster.
- Deploy workloads to the new cluster.
- Validate before deleting the old cluster.
- Practice blue-green thinking at cluster level.

### Exercise 2: Data-Plane Maintenance

Drain the worker:

```powershell
.\scripts\06-simulate-data-plane-upgrade.ps1
```

What this teaches:

- Cordon prevents new pods from scheduling.
- Drain evicts existing pods safely.
- PDB can protect or block disruption.
- Workloads must have enough replicas and capacity.
- Uncordon returns node to service.

## Real kubeadm Control Plane Upgrade Summary

High-level only:

```bash
kubeadm upgrade plan
kubeadm upgrade apply vX.Y.Z
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=X.Y.Z-* kubectl=X.Y.Z-*
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet
```

For additional control-plane nodes:

```bash
kubeadm upgrade node
```

## Real kubeadm Worker Upgrade Summary

On each worker:

```bash
kubectl drain NODE --ignore-daemonsets --delete-emptydir-data
apt-mark unhold kubeadm kubelet kubectl
apt-get install -y kubeadm=X.Y.Z-* kubelet=X.Y.Z-* kubectl=X.Y.Z-*
kubeadm upgrade node
systemctl daemon-reload
systemctl restart kubelet
kubectl uncordon NODE
```

## Real EKS Upgrade Summary

Typical EKS order:

1. Check Kubernetes version skew and deprecated APIs.
2. Upgrade EKS control plane.
3. Upgrade EKS add-ons.
4. Upgrade managed node groups by replacing nodes.
5. Drain and validate workloads.
6. Monitor application health.

## Common Upgrade Issues

- Deprecated API versions removed in the target Kubernetes version.
- PDB blocks node drain.
- Single-replica app causes downtime during node maintenance.
- Insufficient node capacity after cordon.
- CNI, CoreDNS, kube-proxy, or CSI versions incompatible.
- Webhook certificates expired.
- Admission webhook blocks new pods.
- Ingress controller or service mesh incompatible.
- Container image pull issues after node replacement.
- Storage volumes stuck during node drain.
