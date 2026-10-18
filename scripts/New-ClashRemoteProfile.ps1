#Requires -Version 7.0
<#
.SYNOPSIS
    创建一个固定地址的远程订阅（配置存服务端，节点走 proxy-providers）。

.EXAMPLE
    $env:CLASH_SUB_TOKEN = 'your-token'
    pwsh ./scripts/New-ClashRemoteProfile.ps1 -SubscriptionUrl 'https://example.com/sub' -Name main
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SubscriptionUrl,

    [string]$Name = 'main',

    [string]$WorkerBase = $env:CLASH_WORKER_BASE,

    [string]$Token = $env:CLASH_SUB_TOKEN,

    [ValidateSet('standard', 'minimal', 'none')]
    [string]$RuleSet = 'standard',

    [string]$ProfilesFile = 'profiles.json'
)

$ErrorActionPreference = 'Stop'

if (-not $WorkerBase) {
    $WorkerBase = 'https://clash-sub.rdone.workers.dev'
}

$query = 'url=' + [Uri]::EscapeDataString($SubscriptionUrl)
$query += '&ruleset=' + $RuleSet

$body = @{ query = $query } | ConvertTo-Json -Compress
$uri = $WorkerBase.TrimEnd('/') + '/api/profiles'
if ($Token) { $uri += '?token=' + [Uri]::EscapeDataString($Token) }

try {
    $result = Invoke-RestMethod -Uri $uri -Method Post `
        -ContentType 'application/json; charset=utf-8' `
        -Body $body -TimeoutSec 60
} catch {
    throw "创建失败：$($_.ErrorDetails.Message)"
}

$profiles = @()
if (Test-Path -LiteralPath $ProfilesFile) {
    $raw = Get-Content -LiteralPath $ProfilesFile -Raw
    if ($raw.Trim()) { $profiles = @($raw | ConvertFrom-Json) }
}
$profiles = @($profiles | Where-Object { $_.name -ne $Name })
$profiles += [pscustomobject]@{
    name            = $Name
    id              = $result.id
    url             = $result.url
    subscriptionUrl = $SubscriptionUrl
    ruleSet         = $RuleSet
    updatedAt       = (Get-Date).ToString('o')
}

$profiles | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ProfilesFile -Encoding utf8

Write-Host "已创建远程订阅：$Name" -ForegroundColor Green
Write-Host "  订阅地址：$($result.url)"
Write-Host "  网页编辑：$($result.editUrl)"
Write-Host "  本地记录：$ProfilesFile"
