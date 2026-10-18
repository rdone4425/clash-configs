# Clash Configs

Clash / Mihomo 配置模板，可直接导入 Clash Verge Rev、Mihomo Party、ClashX Meta。

## 配置

| 文件 | 说明 |
| --- | --- |
| `configs/clash-standard.yaml` | 内联节点 + 19 个 geosite 规则集，3 个示例节点 / 17 个组 / 33 条规则 |
| `configs/clash-minimal.yaml` | 精简：只做私有地址和国内直连，不依赖外部规则集 |
| `configs/clash-remote.yaml` | 远程：`proxies: []`，节点由 `proxy-providers` 定时拉取 |

## 使用

1. 把对应文件复制到 Clash 配置目录，或用客户端「导入本地配置」。
2. 把 `proxies` 里的示例节点替换成自己的节点。
3. `clash-remote.yaml` 需要把 `YOUR-PROFILE-ID` 换成自己的远程订阅 id。

示例节点使用 `203.0.113.x`（RFC 5737 文档地址），不能连通，使用前替换。

## 规则集

域名规则来自 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的 geosite `mrs` 文件，通过 `rule-providers` 下发，Clash 每 24 小时更新一次。首次加载会下载约 1–2 MB。

## 分组

- 策略组：节点选择 / 自动选择 / 故障转移 / 负载均衡
- 应用组：AI 服务 / YouTube / 谷歌服务 / X / 国外媒体 / 电报 / 苹果服务 / 微软服务 / 游戏平台 / 开发服务
- 兜底：全球直连 / 广告拦截 / 漏网之鱼

## 安全

示例配置不含订阅地址、节点密码或令牌；替换成真实节点后，不要把配置提交到公开仓库。
