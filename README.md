# Clash Sub

Clash / Mihomo 订阅网关 + 配置模板 + 在线展示页。一个仓库，两个部署平台。

| 平台 | 部署内容 | 地址 |
| --- | --- | --- |
| GitHub Pages | 配置展示页 + 配置模板 | https://rdone4425.github.io/clash-configs/ |
| Cloudflare Workers | 订阅网关 Worker | https://clash-gateway.rdone.eu.cc/ |

## 结构

```
configs/                      Clash 配置模板
  clash-standard.yaml           内联节点 + geosite 规则集
  clash-minimal.yaml            精简（只做国内直连）
  clash-remote.yaml             远程模板（proxy-providers）
gateway/                      Cloudflare Worker 订阅网关
  src/index.js                  路由与配置生成
  src/parser.js                 订阅解析（vmess/vless/trojan/ss/ssr/hysteria2/tuic/socks/http）
  wrangler.example.jsonc        配置示例（公开仓库，占位 token）
  wrangler.jsonc                本地真实配置（已 gitignore，含 ACCESS_TOKEN）
index.html                    Pages 首页（查看配置 / 生成订阅）
scripts/parse-subscription.mjs  本地解析脚本
```

## 部署

### GitHub Pages

push 到 `main` 自动构建，无需配置。

### Cloudflare Workers

**本地部署：**

```bash
npm run gateway:deploy
```

首次使用前：

```bash
cp gateway/wrangler.example.jsonc gateway/wrangler.jsonc
# 编辑 gateway/wrangler.jsonc，把 ACCESS_TOKEN 换成你自己的值
npm run gateway:install
```

**GitHub Actions 自动部署：**

`.github/workflows/deploy-worker.yml` 会在 `gateway/**` 变更或手动触发时部署。
需要在仓库 Secrets 里添加：

- `CLOUDFLARE_API_TOKEN`（Workers 部署权限）
- `CLOUDFLARE_ACCOUNT_ID`
- `ACCESS_TOKEN`（Worker 的调用令牌，替换 wrangler.jsonc 里的占位符）

没配置 Secrets 时，Actions 会自动跳过部署，不会报错。

## Worker 接口

| 路径 | 说明 |
| --- | --- |
| `/sub?token=` | 完整配置：KV 节点直接写入 `proxies`，规则集指向 `/rules/*.mrs` |
| `/provider?token=` | KV 节点列表（proxy-provider 格式） |
| `/rules/*.mrs` | geosite 规则集代理，避开内核直连 jsdelivr 失败 |
| `/api/settings` | GET 读取 / POST 保存 GitHub 配置链接 + 订阅链接（存 KV） |
| `/api/refresh` | 手动刷新 KV 节点 |
| `/health` | 健康检查 |

设置页：`https://clash-gateway.rdone.eu.cc/` — 填 GitHub 配置链接 + 机场订阅 + token，保存即可。

每次 Clash 更新订阅（`/sub`），Worker 会自动：拉机场 → 解析 → 写 KV → 把节点直接写进返回的配置文件。

## 本地生成配置

```bash
npm install
SUBSCRIPTION_URL='https://...' npm run generate
# -> output/clash.yaml, output/provider.yaml
```

## 安全

- `gateway/wrangler.jsonc`（真实 token）已 gitignore，公开仓库里只有占位符示例
- 订阅地址存在 Cloudflare KV，不进仓库
- 别把带 token 的订阅地址发给别人
