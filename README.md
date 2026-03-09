# eze-skills

My Claude Code Skills collection.

## Why

OpenClaw 的联网搜索和浏览器操作体验比 Claude Code 原生好不少，但日常主力还是 CC。于是把 OpenClaw 的联网能力翻译成了 CC skill，让 CC 在处理联网相关任务时拥有同等能力。

## Skills

| Skill | Description | Trigger |
|-------|-------------|---------|
| [daily-news](./daily-news) | 每日资讯日报生成器。三阶段工作流：获取元数据、生成摘要、输出日报 | `/daily-news` |
| [web-access](./web-access) | 让 Claude Code 真正能上网。三层降级链自动选最优方式，CDP 模式持久化登录态，用 agent-browser 精简快照节省 token | 自动触发 |

## Installation

```bash
git clone https://github.com/eze-is/eze-skills.git

# Copy a skill to Claude Code directory
cp -R eze-skills/daily-news ~/.claude/skills/
cp -R eze-skills/web-access ~/.claude/skills/

# web-access 首次使用需运行依赖检查
bash ~/.claude/skills/web-access/scripts/setup.sh
```

### web-access 的三层降级链

遇到联网任务时，CC 会自动按代价从低到高选择方式：

1. **WebSearch**（CC 内置）— 只需搜索结果时，最轻量
2. **WebFetch**（CC 内置）— 读取静态公开页面，无需启动浏览器
3. **agent-browser CDP 模式** — 需要登录或动态渲染时启动真实 Chrome

引入 [agent-browser](https://www.npmjs.com/package/agent-browser) 的核心原因是 accessibility tree 快照比截图节省约 10x token，同时通过独立 Chrome profile 实现登录态持久化，不影响用户自己的浏览器。

## Development

This repository is synced from [eze-skills-private](https://github.com/eze-is/eze-skills-private).

```bash
# Sync from private repo
./sync.sh
```
