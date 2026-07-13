# openspec-superpowers

[![CI](https://github.com/AllenMuu/openspec-superpowers/actions/workflows/validate-schemas.yml/badge.svg?branch=main)](https://github.com/AllenMuu/openspec-superpowers/actions/workflows/validate-schemas.yml)
[![Release](https://img.shields.io/badge/release-v1.1.0-brightgreen)](https://github.com/AllenMuu/openspec-superpowers/releases)
[![OpenSpec](https://img.shields.io/badge/OpenSpec-1.5.0-0277bd)](https://github.com/Fission-AI/OpenSpec)
[![Superpowers](https://img.shields.io/badge/Superpowers-v5.1.0-0277bd)](https://github.com/obra/superpowers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

[English](./README.md) · **简体中文** · [繁體中文](./README.zh-TW.md)

> 社区贡献的 [OpenSpec](https://github.com/Fission-AI/OpenSpec) schema 集合,把 OpenSpec 的 artifact 治理(解决**做什么**)与 [obra/superpowers](https://github.com/obra/superpowers) 的执行技能(解决**怎么做**)桥接起来 —— 一个自包含 bundle,一条命令即可安装。

---

## 🚀 快速安装

在你的**目标仓库根目录**(即你想接入 OpenSpec + Superpowers 的项目)下执行:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh)
```

如需繁体中文的路由规则文本,追加 `--locale zh-TW`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AllenMuu/openspec-superpowers/main/superpowers-bridge/install.sh) --locale zh-TW
```

> 脚本内部已 pin 到发布标签 `v1.1.0`,因此即使从 `main` 分支拉取脚本,它写入的 schema 与路由规则也是可复现的。若想连同脚本本身一起 pin,把 URL 中的 `main` 换成 `v1.1.0` 即可。

### 前置要求

| 要求 | 安装命令 | 说明 |
|------|----------|------|
| `openspec` CLI ≥ 1.5.0 | `brew install openspec` | 缺失或版本 < 1.5.0 时脚本直接中止(需要 v1.5.0 命令集:`propose` / `apply` / `archive` / `explore` / `sync`) |
| Superpowers 插件 | `claude plugin install superpowers@claude-plugins-official` | 缺失时脚本只警告、不中止 |
| `git` | - | 克隆 schema 时需要 |

### 安装脚本做了什么

[`install.sh`](./superpowers-bridge/install.sh) 是幂等的,且**不会执行 git commit** —— 可放心重复运行。它共分六步:

| # | 步骤 | 结果 |
|---|------|------|
| 1 | 前置检查 | 校验 `git`、`openspec ≥ 1.5.0`,并在 Superpowers 插件缺失时给出警告 |
| 2 | `openspec init --tools claude --force` | 生成 `.claude/commands/opsx/*` 与 `.claude/skills/openspec-*/*` |
| 3 | 安装 schema | 把 `superpowers-bridge/` 复制进 `openspec/schemas/`(若已存在则备份而非删除) |
| 4 | 设置默认 schema | 在 `openspec/config.yaml` 写入 `schema: superpowers-bridge` |
| 5 | 工作流路由规则 | 把 v1.5.0 对齐的路由规则写入 `.claude/rules/openspec-routing.md`(由 Claude Code 自动加载;并迁移掉 `CLAUDE.md` 中遗留的 `## Workflow routing` 段) |
| 6 | gitignore + 校验 | 确保 `.claude/settings.local.json` 被 gitignore,然后执行 `openspec schema validate` |

### 安装完成后

1. **重启 Claude Code**,让 `/opsx:*` 斜杠命令加载生效。
2. 发起一次变更:`/opsx:propose <name>`
3. v1.5.0 命令集:`propose` / `apply` / `archive` / `explore` / `sync`(v1.5.0 中**没有** `/opsx:new`、`/opsx:ff`、`/opsx:continue`、`/opsx:verify`)
4. 准备就绪后,提交生成的文件:
   ```bash
   git add .claude/ openspec/ CLAUDE.md .gitignore
   git commit -m "chore(openspec): install superpowers-bridge"
   ```

> 想要引导式安装,或需要升级已有安装?完整指南见 [`superpowers-bridge/README.md`](./superpowers-bridge/README.md)(含一次性 Claude Code prompt、手动 bash 步骤,以及升级路径)。

---

## 🧩 Bridges

| Bridge | 用途 | 状态 |
|--------|------|------|
| [`superpowers-bridge`](./superpowers-bridge/) | 把 OpenSpec 的 artifact 治理与 [obra/superpowers](https://github.com/obra/superpowers) 的执行技能(brainstorming、writing-plans、TDD-via-subagents、code review、finishing)串接成一个工作流。额外加上 evidence-first 的 `retrospective` artifact,补齐 Superpowers 原生没有的 retro 能力。 | v1 |

> 想新增一个 bridge?在仓库根目录建一个 `<new-bridge>/` 子目录,结构参照 `superpowers-bridge/`,然后在 [`.github/workflows/validate-schemas.yml`](./.github/workflows/validate-schemas.yml) 的 `matrix.bridge` 里加一行即可。

---

## ❓ 为什么单独开一个仓库?

[OpenSpec PR #970](https://github.com/Fission-AI/OpenSpec/pull/970) 最初提议把 `sdd-plus-superpowers` 收为内建 schema。维护者评审后建议改为社区仓库 —— 这与 [github/spec-kit 的 community extension catalog](https://speckit-community.github.io/extensions/) 处理第三方工具整合的模式一致:让它们待在社区层,不进 core。

好处:

- **OpenSpec core 不与 Superpowers 的发布节奏绑定**
- **bridge 可独立迭代**,按自己的节奏发版
- **其他社区 schema 之后可以 sibling 形式加入本仓库**

---

## 🛣️ Roadmap

未来规划见 [`docs/roadmap.md`](./docs/roadmap.md)(v1 已发布、v1.x 待办、以及等待 OpenSpec core 推进的事项)。

---

## 📄 License

MIT —— 详见 [LICENSE](./LICENSE)。
