[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$required = @("docker", "kind", "kubectl")
$missing = @()

foreach ($cmd in $required) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Host "[MISSING] $cmd"
        $missing += $cmd
        continue
    }

    Write-Host "[OK] $cmd -> $($found.Source)"
    try {
        if ($cmd -eq "docker") {
            docker version --format "{{.Client.Version}}"
        }
        elseif ($cmd -eq "kind") {
            kind version
        }
        elseif ($cmd -eq "kubectl") {
            kubectl version --client=true
        }
    }
    catch {
        Write-Host "[WARN] $cmd exists, but version check failed: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Docker daemon check"
docker info 1>$null 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Docker daemon is running"
}
else {
    Write-Host "[WARN] Docker CLI exists, but Docker Desktop daemon is not running"
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Install missing tools before continuing: $($missing -join ', ')"
    exit 1
}

Write-Host ""
Write-Host "Preflight finished"
