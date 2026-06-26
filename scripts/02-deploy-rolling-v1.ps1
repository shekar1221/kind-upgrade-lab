[CmdletBinding()]
param(
    [string]$Namespace = "rollout-lab"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")

kubectl apply -f (Join-Path $LabRoot "manifests\base\namespace.yaml")
kubectl apply -f (Join-Path $LabRoot "manifests\rolling\rolling-v1.yaml")
kubectl rollout status deployment/payments-rolling -n $Namespace --timeout=120s
kubectl get pods -n $Namespace -o wide
kubectl get svc,endpoints -n $Namespace

Write-Host ""
Write-Host "Test:"
Write-Host "kubectl port-forward svc/payments-rolling 8080:80 -n $Namespace"
Write-Host "Open http://localhost:8080"
