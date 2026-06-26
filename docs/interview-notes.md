# Interview Notes

## 60 Second Explanation

I built a local Kubernetes upgrade and rollout lab using kind with one control-plane node and one worker node. I practiced rolling, blue-green, and canary deployment strategies. For data-plane upgrades, I used cordon and drain to safely evict pods from the worker node, then uncordoned it after the simulated patch. For control-plane upgrades in kind, I used a blue-green replacement cluster because kind is not a production in-place upgrade manager. I also created failure drills for ImagePullBackOff, readiness failures, service selector mistakes, PDB drain blockage, and bad canary releases.

## Rolling Strategy Answer

Rolling update gradually replaces old pods with new pods. I used `maxSurge=1` and `maxUnavailable=0` to keep availability during update. I validated using `kubectl rollout status`, checked ReplicaSets, and kept `kubectl rollout undo` ready.

## Blue-Green Strategy Answer

Blue-green runs old and new versions side by side. Traffic is switched by changing the Service selector from blue to green. Rollback is fast because the blue version still exists.

## Canary Strategy Answer

Canary sends a small portion of traffic to the new version. In this lab I used pod ratio as the traffic weight. In production I would use ingress, service mesh, or progressive delivery tooling with metrics-based gates.

## Control Plane Upgrade Answer

In production, the control plane is upgraded first. For EKS, AWS manages the control plane upgrade and then the team upgrades managed node groups and add-ons. For kubeadm, I would run upgrade plan, upgrade apply, then update kubelet and kubectl. In kind, I practiced this as a replacement cluster because kind clusters are disposable Docker-based clusters.

## Data Plane Upgrade Answer

Data plane means worker nodes and runtime. The safe flow is cordon, drain, patch or replace, validate, and uncordon. Before draining I check replicas, PDBs, capacity, and local storage.

## Failure Examples To Mention

- PDB too strict blocks node drain.
- Readiness probe failure causes Service to have no ready endpoints.
- Bad image tag causes ImagePullBackOff.
- Service selector mismatch gives no endpoints.
- Bad canary impacts limited traffic and can be rolled back quickly.
- DB migration incompatibility can break rolling deployment.
