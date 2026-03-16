# eze-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一泽Eze 的 Claude Code Skills 公开合集。把日常高频用到的能力封装成 skill，让 Claude Code 开箱即用。

## Install

```bash
# 通过 Claude Code 插件市场安装
/plugin marketplace add eze-is/eze-skills

# 安装单个 skill
/plugin install web-access@eze-skills
/plugin install daily-news@eze-skills
```

或手动 clone：

```bash
git clone https://github.com/eze-is/eze-skills.git
cp -R eze-skills/web-access ~/.claude/skills/
cp -R eze-skills/daily-news ~/.claude/skills/
```

---

## Skills

| Skill | 简介 | 触发方式 |
|-------|------|---------|
| [web-access](./web-access) | 让 Claude Code 真正能上网，支持登录态持久化 | 自动触发 |
| [daily-news](./daily-news) | 每日资讯日报生成器，支持自定义信源 | 自动触发 |

---

## web-access

Claude Code 原生有联网能力，但降级策略不完善，也不支持持久化登录。web-access 在原有基础上补全了整个联网操作链路，以**「像人一样浏览」**为核心理念：带着目标进入，边看边判断，遇到阻碍在层内解决，不打扰用户。

遇到联网任务时自动按代价从低到高选择方式：

1. **WebSearch** — 只需搜索结果，最轻量
2. **Jina**（默认）— 底层执行 JS 渲染，提取正文为 Markdown，支持 SPA、PDF，token 消耗低
3. **WebFetch** — 直接获取原始 HTML（不执行 JS），用于读取服务端静态嵌入的结构化字段（meta、JSON-LD 等）
4. **agent-browser CDP 模式** — 非公开内容、已知反爬平台（小红书、微信公众号等）或需要交互时使用

引入 [agent-browser](https://www.npmjs.com/package/agent-browser) 的原因：accessibility tree 快照比截图节省约 10x token，独立 Chrome profile 实现登录态持久化，不影响用户自己的浏览器。

首次使用需检查依赖：

```bash
bash ~/.claude/skills/web-access/scripts/check-deps.sh
```

---

## daily-news

三阶段工作流：**获取元数据 → 生成摘要 → 输出日报**。支持自定义信源，适合需要每日信息聚合的场景。

工作区结构：

```
<workspace>/
├── profile.yaml      # 用户画像（关注什么）
├── settings.yaml     # 日报设置
├── methods/          # 信源获取方法
├── data/news.db      # SQLite 数据库
└── output/           # 生成的日报
```

---

> Synced from [eze-skills-private](https://github.com/eze-is/eze-skills-private).
