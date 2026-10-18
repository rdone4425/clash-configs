# Clash Configs

Clash / Mihomo 配置模板，可直接导入 Clash Verge Rev、Mihomo Party、ClashX Meta。

## 配置

| 文件 | 说明 |
| --- | --- |
| `configs/clash-standard.yaml` | 内联节点 + 23 个 geosite 规则集，3 个示例节点 / 23 个组 / 40 条规则 |
| `configs/clash-minimal.yaml` | 精简：只做私有地址和国内直连，不依赖外部规则集 |
| `configs/clash-remote.yaml` | 远程：`proxies: []`，节点由 `proxy-providers` 定时拉取 |

## 使用

1. 把对应文件复制到 Clash 配置目录，或用客户端「导入本地配置」。
2. 把 `proxies` 里的示例节点替换成自己的节点。
3. `clash-remote.yaml` 需要把 `YOUR-PROFILE-ID` 换成自己的远程订阅 id。

示例节点使用 `203.0.113.x`（RFC 5737 文档地址），不能连通，使用前替换。

## 在线生成远程订阅

页面顶部的「生成远程订阅」：填机场订阅地址和 `ACCESS_TOKEN`，点生成，得到：

```
https://clash-gateway.rdone.workers.dev/s/<id>
```

把它填进 Clash。节点通过 `/provider/<id>` 远程拉取，规则通过 `rule-providers` 远程加载，配置里不写死节点和规则。

- 订阅地址存在 Cloudflare KV，不写入 GitHub
- 删除：`DELETE /api/profiles/<id>`（带 token）

## 本地生成（不保存节点到 GitHub）

脚本在 `scripts/parse-subscription.mjs`，只在本机运行，节点不会提交、不会上传：

```powershell
npm install
$env:SUBSCRIPTION_URL = 'https://example.com/sub'
node scripts/parse-subscription.mjs
```

生成两个文件：

- `output/clash.yaml`：完整配置，以 `configs/clash-standard.yaml` 为模板，自动替换节点和组引用
- `output/provider.yaml`：只含 `proxies`，可以直接作为 `proxy-provider` 使用

支持 vmess / vless / trojan / ss / ssr / hysteria2 / tuic / socks5 / http；订阅可以是 Base64、明文链接或 Clash YAML。

| 环境变量 | 默认 | 说明 |
| --- | --- | --- |
| `SUBSCRIPTION_URL` | 必填 | 机场订阅地址 |
| `SUBSCRIPTION_UA` | `v2rayN/6.42` | 拉取订阅的 UA |
| `TEMPLATE` | `configs/clash-standard.yaml` | 配置模板 |
| `OUT_DIR` | `output` | 输出目录 |

> 生成的文件包含节点密码 / UUID，已在 `.gitignore` 中忽略，不要提交。
> 之所以不做成 GitHub Actions：仓库是 public，Actions 的 artifact 和日志对所有人可见，等于公开你的节点。需要定时自动更新的话，应该用私有运行时（比如一个带 token 的 Worker），而不是公共仓库。

## 规则集

域名规则来自 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的 geosite `mrs` 文件，通过 `rule-providers` 下发，Clash 每 24 小时更新一次。首次加载会下载约 1–2 MB。

## 分组

- 策略组：节点选择 / 自动选择 / 故障转移 / 负载均衡
- 应用组：AI 服务 / YouTube / 谷歌服务 / X / Meta（Facebook + Instagram）/ Netflix / Disney+ / Spotify / 国外媒体 / 电报 / 苹果服务 / 微软服务 / 游戏平台 / 开发服务 / 加密货币 / 测速
- 兜底：全球直连 / 广告拦截 / 漏网之鱼

## 安全

示例配置不含订阅地址、节点密码或令牌；替换成真实节点后，不要把配置提交到公开仓库。
