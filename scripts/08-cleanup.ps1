[CmdletBinding()]
param(
    [string[]]$ClusterNames = @("kind-upgrade-lab", "kind-upgrade-lab-green")
)

$ErrorActionPreference = "Continue"

foreach ($cluster in $ClusterNames) {
    $existing = kind get clusters 2>$null | Where-Object { $_ -eq $cluster }
    if ($existing) {
        Write-Host "Deleting cluster $cluster"
        kind delete cluster --name $cluster
    }
    else {
        Write-Host "Cluster $cluster not found"
    }
}
