[CmdletBinding()]
param(
    [int]$StableReplicas = 4,
    [int]$CanaryReplicas = 1,
    [string]$Namespace = "rollout-lab"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")

kubectl apply -f (Join-Path $LabRoot "manifests\base\namespace.yaml")
kubectl apply -f (Join-Path $LabRoot "manifests\canary\canary.yaml")
kubectl scale deployment/payments-stable -n $Namespace --replicas=$StableReplicas
kubectl scale deployment/payments-canary -n $Namespace --replicas=$CanaryReplicas
kubectl rollout status deployment/payments-stable -n $Namespace --timeout=120s
kubectl rollout status deployment/payments-canary -n $Namespace --timeout=120s

$total = $StableReplicas + $CanaryReplicas
if ($total -gt 0) {
    $percentage = [math]::Round(($CanaryReplicas / $total) * 100, 2)
    Write-Host "Approximate canary weight by pod count: $percentage%"
}

kubectl get pods -n $Namespace -l app=payments-canary --show-labels -o wide
kubectl get svc,endpoints -n $Namespace

Write-Host ""
Write-Host "Rollback canary:"
Write-Host "kubectl scale deployment/payments-canary -n $Namespace --replicas=0"
