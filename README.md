# eze-skills

一泽Eze 的 Claude Code Skills 公开合集。

把日常高频用到的能力封装成 skill，让 Claude Code 开箱即用。

---

## Skills

| Skill | 简介 | 触发方式 |
|-------|------|---------|
| [daily-news](./daily-news) | 每日资讯日报生成器 | `/daily-news` |
| [web-access](./web-access) | 让 Claude Code 真正能上网 | 自动触发 |

---

## daily-news

三阶段工作流：获取元数据 → 生成摘要 → 输出日报。支持自定义信源，适合需要每日信息聚合的场景。

## web-access

Claude Code 原生不联网，web-access 补上了这块能力。灵感来自 OpenClaw 的联网流程，翻译成 CC skill 后日常直接用。

遇到联网任务时自动按代价从低到高选择方式：

1. **WebSearch** — 只需搜索结果，最轻量
2. **WebFetch** — 读取静态公开页面，不启动浏览器
3. **agent-browser CDP 模式** — 需要登录或动态渲染时启动真实 Chrome

引入 [agent-browser](https://www.npmjs.com/package/agent-browser) 的原因：accessibility tree 快照比截图节省约 10x token，独立 Chrome profile 实现登录态持久化，不影响用户自己的浏览器。

---

## Installation

```bash
git clone https://github.com/eze-is/eze-skills.git

# 复制需要的 skill 到 Claude Code 目录
cp -R eze-skills/daily-news ~/.claude/skills/
cp -R eze-skills/web-access ~/.claude/skills/
```

web-access 首次使用需检查依赖：

```bash
bash ~/.claude/skills/web-access/scripts/setup.sh
```

---

This repository is synced from [eze-skills-private](https://github.com/eze-is/eze-skills-private).
