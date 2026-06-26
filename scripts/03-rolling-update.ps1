[CmdletBinding()]
param(
    [string]$Namespace = "rollout-lab"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")

Write-Host "Current rollout history"
kubectl rollout history deployment/payments-rolling -n $Namespace

Write-Host "Applying v2 with RollingUpdate maxSurge=1 maxUnavailable=0"
kubectl apply -f (Join-Path $LabRoot "manifests\rolling\rolling-v2.yaml")
kubectl rollout status deployment/payments-rolling -n $Namespace --timeout=120s

Write-Host "After rollout"
kubectl get rs,pods -n $Namespace -l app=payments-rolling -o wide
kubectl rollout history deployment/payments-rolling -n $Namespace

Write-Host ""
Write-Host "Rollback command if needed:"
Write-Host "kubectl rollout undo deployment/payments-rolling -n $Namespace"
