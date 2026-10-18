#!/usr/bin/env node
/**
 * 校验 Clash / Mihomo 配置：节点、分组、规则之间的引用是否完整。
 * 用法：node scripts/validate-config.mjs [files...]
 */
import { readFile } from "node:fs/promises";
import { parse } from "yaml";

const DEFAULT_FILES = [
  "configs/clash-standard.yaml",
  "configs/clash-minimal.yaml",
  "configs/clash-remote.yaml",
];

const targets = process.argv.slice(2);
const files = targets.length > 0 ? targets : DEFAULT_FILES;

let failed = false;

for (const file of files) {
  try {
    const doc = parse(await readFile(file, "utf8"));
    const errors = [];

    if (!doc || typeof doc !== "object") {
      errors.push("不是有效的 YAML 对象");
    }

    const proxies = Array.isArray(doc?.proxies) ? doc.proxies : [];
    const providers = doc?.["proxy-providers"] ? Object.keys(doc["proxy-providers"]) : [];
    const groups = Array.isArray(doc?.["proxy-groups"]) ? doc["proxy-groups"] : [];
    const rules = Array.isArray(doc?.rules) ? doc.rules : [];

    if (proxies.length === 0 && providers.length === 0) {
      errors.push("既没有 proxies 也没有 proxy-providers");
    }
    if (groups.length === 0) errors.push("缺少 proxy-groups");
    if (rules.length === 0) errors.push("缺少 rules");

    const groupNames = new Set(groups.map((group) => group.name));
    const nodeNames = new Set(proxies.map((proxy) => proxy.name));
    const ruleProviders = doc?.["rule-providers"] ?? {};

    for (const group of groups) {
      if (!group.name) errors.push("proxy-group 缺少 name");

      for (const target of group.proxies ?? []) {
        if (target === "DIRECT" || target === "REJECT") continue;
        if (!groupNames.has(target) && !nodeNames.has(target)) {
          errors.push(`组 ${group.name} 引用了不存在的 ${target}`);
        }
      }

      for (const provider of group.use ?? []) {
        if (!providers.includes(provider)) {
          errors.push(`组 ${group.name} 引用了不存在的 proxy-provider ${provider}`);
        }
      }
    }

    for (const rule of rules) {
      if (typeof rule !== "string") {
        errors.push("rules 里有非字符串项");
        continue;
      }

      const parts = rule.split(",");

      if (parts[0] === "RULE-SET") {
        if (!ruleProviders[parts[1]]) {
          errors.push(`规则引用了不存在的 rule-provider: ${parts[1]}`);
        }
        if (!groupNames.has(parts[2])) {
          errors.push(`规则目标组不存在: ${parts[2]}（${rule}）`);
        }
        continue;
      }

      const target = parts.at(-1) === "no-resolve" ? parts.at(-2) : parts.at(-1);
      if (!target) {
        errors.push(`规则格式不正确: ${rule}`);
        continue;
      }
      if (!groupNames.has(target) && target !== "DIRECT" && target !== "REJECT") {
        errors.push(`规则目标组不存在: ${target}（${rule}）`);
      }
    }

    if (errors.length > 0) {
      failed = true;
      console.error(`✗ ${file}`);
      for (const error of [...new Set(errors)]) console.error(`  - ${error}`);
    } else {
      console.log(
        `✓ ${file}  ${proxies.length} nodes / ${groups.length} groups / ${rules.length} rules`,
      );
    }
  } catch (error) {
    failed = true;
    console.error(`✗ ${file}: ${error.message}`);
  }
}

if (failed) process.exit(1);
