# Clash Configs

Clash / Mihomo 配置模板 + 订阅管理脚本，配合 [clash-sub](https://clash-sub.rdone.workers.dev) 使用：把机场订阅转换成可以直接导入 Clash Verge Rev / Mihomo Party 的配置。

## 目录

```
configs/
  clash-standard.yaml     # 内联节点 + geosite 规则集（17 个 rule-providers）
  clash-minimal.yaml      # 精简：只做国内直连，无外部依赖
  clash-remote.yaml       # 远程：节点走 proxy-providers
scripts/
  Convert-ClashSubscription.ps1   # 订阅 → 本地 YAML
  New-ClashRemoteProfile.ps1      # 创建固定地址的远程订阅
  Sync-ClashProfiles.ps1          # 批量更新远程订阅
  Test-ClashConfig.ps1            # 校验配置引用
  validate-config.mjs             # Node 校验器
profiles.example.json
```

## 要求

- PowerShell 7+
- Node.js 20+（只用于校验，可选）

## 环境变量

```powershell
$env:CLASH_WORKER_BASE = 'https://clash-sub.rdone.workers.dev'
$env:CLASH_SUB_TOKEN = '你的访问令牌'
```

`CLASH_WORKER_BASE` 不设置时默认就是上面的地址；`CLASH_SUB_TOKEN` 不设置时按无令牌处理。

## 1. 生成一份本地配置

```powershell
pwsh ./scripts/Convert-ClashSubscription.ps1 -SubscriptionUrl 'https://example.com/sub'
# -> configs/generated.yaml
```

指定规则集：

```powershell
pwsh ./scripts/Convert-ClashSubscription.ps1 `
  -SubscriptionUrl 'https://example.com/sub' `
  -RuleSet minimal `
  -OutFile configs/minimal.yaml
```

## 2. 创建固定地址的远程订阅

```powershell
pwsh ./scripts/New-ClashRemoteProfile.ps1 -SubscriptionUrl 'https://example.com/sub' -Name main
```

输出类似：

```
订阅地址：https://clash-sub.rdone.workers.dev/s/xxxx
网页编辑：https://clash-sub.rdone.workers.dev/?profile=xxxx&token=...
```

把「订阅地址」填进 Clash。节点通过 `proxy-providers` 定时拉取，分组和规则由服务端生成；改完分组重新保存即可，订阅地址不变。

## 3. 批量更新

```powershell
pwsh ./scripts/Sync-ClashProfiles.ps1 -Download
```

读取 `profiles.json`，逐个更新远程配置；`-Download` 同时把 `/s/<id>` 下载到 `configs/<name>.yaml`。

## 4. 校验

```powershell
npm install
npm run validate

# 或只校验单个文件
pwsh ./scripts/Test-ClashConfig.ps1 -Path configs/clash-standard.yaml
```

校验内容：组是否引用了不存在的节点 / 组 / provider、规则目标组是否存在、`rule-providers` 是否声明。

## 配置说明

- `clash-standard.yaml`：3 个示例节点 + 14 个组 + 31 条规则。域名规则来自 [meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的 `mrs` 规则集，首次加载会下载约 1–2 MB。
- `clash-minimal.yaml`：只有私有地址 + `GEOIP,CN`，不依赖任何外部规则集。
- `clash-remote.yaml`：`proxies: []`，节点由 `proxy-providers.remote` 提供；把 `YOUR-PROFILE-ID` 换成自己的 id。

示例节点使用 `203.0.113.x`（文档专用地址），不能连通，使用前替换成自己的订阅或节点。

## 安全

- `profiles.json` 含远程订阅 id（相当于凭证），已在 `.gitignore` 中忽略，不要提交。
- `CLASH_SUB_TOKEN` 只放在环境变量里，不要写进仓库。
- 仓库默认私有；如果要公开，先确认配置里没有订阅地址、节点密码或令牌。

## 相关

- 规则集：[MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)
- Worker 源码与部署说明：见 `clash-sub` 项目
