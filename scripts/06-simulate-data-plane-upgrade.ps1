[CmdletBinding()]
param(
    [string]$ClusterName = "kind-upgrade-lab",
    [string]$WorkerNode = ""
)

$ErrorActionPreference = "Continue"

if ($WorkerNode.Trim().Length -eq 0) {
    $WorkerNode = "$ClusterName-worker"
}

Write-Host "Before drain"
kubectl get nodes -o wide
kubectl get pods -A -o wide

Write-Host ""
Write-Host "Cordoning worker node $WorkerNode"
kubectl cordon $WorkerNode

Write-Host ""
Write-Host "Draining worker node $WorkerNode"
kubectl drain $WorkerNode --ignore-daemonsets --delete-emptydir-data --force --timeout=120s
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[WARN] Drain failed. Common reasons: PDB too strict, single replica workload, local storage, or no schedulable capacity."
    Write-Host "Run: kubectl describe node $WorkerNode"
    Write-Host "Run: kubectl get pdb -A"
    exit 1
}

Write-Host ""
Write-Host "Simulated patching window: this is where real teams patch OS, kubelet, runtime, AMI, or node image."
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Uncordoning worker node $WorkerNode"
kubectl uncordon $WorkerNode

Write-Host ""
Write-Host "After maintenance"
kubectl get nodes -o wide
kubectl get pods -A -o wide
