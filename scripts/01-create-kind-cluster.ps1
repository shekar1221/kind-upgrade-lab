[CmdletBinding()]
param(
    [string]$ClusterName = "kind-upgrade-lab",
    [string]$NodeImage = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Resolve-Path (Join-Path $ScriptDir "..")
$Config = Join-Path $LabRoot "configs\kind-2node.yaml"

$existing = kind get clusters | Where-Object { $_ -eq $ClusterName }
if ($existing) {
    Write-Host "Cluster $ClusterName already exists"
    kubectl config use-context "kind-$ClusterName"
    kubectl get nodes -o wide
    exit 0
}

$args = @("create", "cluster", "--name", $ClusterName, "--config", $Config, "--wait", "120s")
if ($NodeImage.Trim().Length -gt 0) {
    $args += @("--image", $NodeImage)
}

Write-Host "Creating kind cluster $ClusterName"
kind @args

kubectl config use-context "kind-$ClusterName"
kubectl get nodes -o wide
