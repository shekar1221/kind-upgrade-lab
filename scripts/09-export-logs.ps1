[CmdletBinding()]
param(
    [string]$ClusterName = "kind-upgrade-lab",
    [string]$OutputDirectory = ".\kind-logs"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
kind export logs --name $ClusterName $OutputDirectory
Write-Host "Logs exported to $OutputDirectory"
