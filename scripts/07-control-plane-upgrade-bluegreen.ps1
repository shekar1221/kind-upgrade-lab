[CmdletBinding()]
param(
    [string]$OldClusterName = "kind-upgrade-lab",
    [string]$NewClusterName = "kind-upgrade-lab-green",
    [Parameter(Mandatory = $true)]
    [string]$NewNodeImage
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")
$Config = Join-Path $LabRoot "configs\kind-2node.yaml"

Write-Host "Existing clusters"
kind get clusters

$existing = kind get clusters | Where-Object { $_ -eq $NewClusterName }
if (-not $existing) {
    Write-Host "Creating replacement cluster $NewClusterName with image $NewNodeImage"
    kind create cluster --name $NewClusterName --config $Config --image $NewNodeImage --wait 120s
}
else {
    Write-Host "Replacement cluster $NewClusterName already exists"
}

kubectl config use-context "kind-$NewClusterName"
kubectl get nodes -o wide

Write-Host "Deploying workload to replacement cluster"
kubectl apply -f (Join-Path $LabRoot "manifests\base\namespace.yaml")
kubectl apply -f (Join-Path $LabRoot "manifests\rolling\rolling-v2.yaml")
kubectl rollout status deployment/payments-rolling -n rollout-lab --timeout=120s
kubectl get pods -n rollout-lab -o wide

Write-Host ""
Write-Host "Control-plane replacement practice complete."
Write-Host "Old cluster context: kind-$OldClusterName"
Write-Host "New cluster context: kind-$NewClusterName"
Write-Host "Switch back if needed: kubectl config use-context kind-$OldClusterName"
Write-Host "Delete old after validation: kind delete cluster --name $OldClusterName"
