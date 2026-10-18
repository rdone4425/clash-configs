#Requires -Version 7.0
<#
.SYNOPSIS
    按 profiles.json 批量更新远程订阅，可选同时下载配置。

.EXAMPLE
    pwsh ./scripts/Sync-ClashProfiles.ps1

.EXAMPLE
    pwsh ./scripts/Sync-ClashProfiles.ps1 -Download
#>
[CmdletBinding()]
param(
    [string]$ProfilesFile = 'profiles.json',

    [string]$WorkerBase = $env:CLASH_WORKER_BASE,

    [string]$Token = $env:CLASH_SUB_TOKEN,

    [switch]$Download
)

$ErrorActionPreference = 'Stop'

if (-not $WorkerBase) {
    $WorkerBase = 'https://clash-sub.rdone.workers.dev'
}

if (-not (Test-Path -LiteralPath $ProfilesFile)) {
    throw "找不到 $ProfilesFile，先运行 scripts/New-ClashRemoteProfile.ps1"
}

$profiles = @(Get-Content -LiteralPath $ProfilesFile -Raw | ConvertFrom-Json)
if ($profiles.Count -eq 0) {
    Write-Warning 'profiles.json 里没有配置'
    return
}

$hasError = $false

foreach ($profile in $profiles) {
    if (-not $profile.id -or -not $profile.subscriptionUrl) {
        Write-Warning "跳过 $($profile.name)：缺少 id 或 subscriptionUrl"
        continue
    }

    $ruleSet = if ($profile.ruleSet) { $profile.ruleSet } else { 'standard' }
    $query = 'url=' + [Uri]::EscapeDataString($profile.subscriptionUrl) + '&ruleset=' + $ruleSet
    $body = @{ query = $query } | ConvertTo-Json -Compress
    $uri = $WorkerBase.TrimEnd('/') + '/api/profiles/' + $profile.id
    if ($Token) { $uri += '?token=' + [Uri]::EscapeDataString($Token) }

    try {
        $result = Invoke-RestMethod -Uri $uri -Method Put `
            -ContentType 'application/json; charset=utf-8' `
            -Body $body -TimeoutSec 60
        Write-Host "OK  $($profile.name) -> $($result.url)" -ForegroundColor Green

        if ($Download) {
            $outFile = Join-Path 'configs' ($profile.name + '.yaml')
            New-Item -ItemType Directory -Force -Path 'configs' | Out-Null
            $configUri = $WorkerBase.TrimEnd('/') + '/s/' + $profile.id
            Invoke-WebRequest -Uri $configUri -UseBasicParsing -TimeoutSec 60 -OutFile $outFile
            Write-Host "    下载到 $outFile" -ForegroundColor DarkGray
        }
    } catch {
        $hasError = $true
        Write-Error "失败 $($profile.name)：$($_.ErrorDetails.Message)"
    }
}

if ($hasError) { exit 1 }
