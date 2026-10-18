#Requires -Version 7.0
<#
.SYNOPSIS
    校验 Clash / Mihomo YAML 配置的组引用与规则引用。

.EXAMPLE
    pwsh ./scripts/Test-ClashConfig.ps1 -Path configs/clash-standard.yaml
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
    throw "文件不存在：$Path"
}

$yamlModule = Join-Path (Get-Location) 'node_modules/yaml'
if (-not (Test-Path -LiteralPath $yamlModule)) {
    throw '缺少 yaml 依赖，先执行：npm install'
}

$validator = Join-Path $PSScriptRoot 'validate-config.mjs'
& node $validator $Path
exit $LASTEXITCODE
