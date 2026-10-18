#Requires -Version 7.0
<#
.SYNOPSIS
    从机场订阅链接生成 Clash / Mihomo 配置。

.EXAMPLE
    $env:CLASH_SUB_TOKEN = 'your-token'
    pwsh ./scripts/Convert-ClashSubscription.ps1 -SubscriptionUrl 'https://example.com/sub'

.EXAMPLE
    pwsh ./scripts/Convert-ClashSubscription.ps1 `
        -SubscriptionUrl 'https://example.com/sub' `
        -RuleSet minimal `
        -OutFile 'configs/minimal.yaml'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SubscriptionUrl,

    [string]$WorkerBase = $env:CLASH_WORKER_BASE,

    [string]$Token = $env:CLASH_SUB_TOKEN,

    [ValidateSet('standard', 'minimal', 'none')]
    [string]$RuleSet = 'standard',

    [string]$OutFile = 'configs/generated.yaml',

    [switch]$NoCache
)

$ErrorActionPreference = 'Stop'

if (-not $WorkerBase) {
    $WorkerBase = 'https://clash-sub.rdone.workers.dev'
}

$query = 'url=' + [Uri]::EscapeDataString($SubscriptionUrl)
$query += '&ruleset=' + $RuleSet
if ($Token) { $query += '&token=' + [Uri]::EscapeDataString($Token) }
if ($NoCache) { $query += '&ttl=0' }

$uri = $WorkerBase.TrimEnd('/') + '/sub?' + $query
Write-Host "GET $uri" -ForegroundColor DarkGray

$response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 90 -SkipHttpErrorCheck

if ($response.StatusCode -ne 200) {
    $message = $response.Content
    if ($message -is [byte[]]) { $message = [Text.Encoding]::UTF8.GetString($message) }
    throw "转换失败（HTTP $($response.StatusCode)）：$message"
}

$text = if ($response.Content -is [byte[]]) {
    [Text.Encoding]::UTF8.GetString($response.Content)
} else {
    [string]$response.Content
}

$full = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutFile))
$dir = Split-Path -Parent $full
if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

[IO.File]::WriteAllText($full, $text, [Text.UTF8Encoding]::new($false))

$size = [Math]::Round((Get-Item -LiteralPath $full).Length / 1KB, 1)
Write-Host "OK -> $full ($size KB)" -ForegroundColor Green
