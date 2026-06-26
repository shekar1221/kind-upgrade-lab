[CmdletBinding()]
param(
    [ValidateSet("blue", "green")]
    [string]$Target = "green",
    [string]$Namespace = "rollout-lab"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")

kubectl apply -f (Join-Path $LabRoot "manifests\base\namespace.yaml")
kubectl apply -f (Join-Path $LabRoot "manifests\blue-green\blue-green.yaml")
kubectl rollout status deployment/payments-blue -n $Namespace --timeout=120s
kubectl rollout status deployment/payments-green -n $Namespace --timeout=120s

Write-Host "Switching Service payments-bg to $Target"
kubectl patch svc payments-bg -n $Namespace -p "{`"spec`":{`"selector`":{`"app`":`"payments-bg`",`"version`":`"$Target`"}}}"

kubectl get svc,endpoints -n $Namespace
kubectl get pods -n $Namespace -l app=payments-bg --show-labels -o wide

Write-Host ""
Write-Host "Rollback switch:"
if ($Target -eq "green") {
    Write-Host ".\scripts\04-blue-green.ps1 -Target blue"
}
else {
    Write-Host ".\scripts\04-blue-green.ps1 -Target green"
}
