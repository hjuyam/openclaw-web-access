# eze-skills

一泽Eze 的 Claude Code Skills 公开合集。

把日常高频用到的能力封装成 skill，让 Claude Code 开箱即用。

---

## Skills

| Skill | 简介 | 触发方式 |
|-------|------|---------|
| [daily-news](./daily-news) | 每日资讯日报生成器 | `/daily-news` |
| [web-access](./web-access) | Claude Code 版本：agent-browser/CDP 持久化登录 | 自动触发 |
| [openclaw-web-access](./openclaw-web-access) | OpenClaw 版本：对齐 web_search/web_fetch/browser（不 kill 系统 Chrome） | 自动触发 |

---

## daily-news

三阶段工作流：获取元数据 → 生成摘要 → 输出日报。支持自定义信源，适合需要每日信息聚合的场景。

## web-access

原始上游（Claude Code）版本：agent-browser/CDP + 独立 Chrome profile 做登录态持久化。

## openclaw-web-access（推荐给 OpenClaw 用户）

这是本 fork 新增的 OpenClaw 版本：把“联网入口”改写为 **OpenClaw 原生工具** 的通道选择与降级策略：

1. **搜索技能（技能树）** — 作为搜索入口（例如 Exa/free 搜索 skill；当 `web_search` 后端不可用时自动降级）
2. **web_fetch** — 已知 URL 的静态公开页面
3. **browser** — 动态渲染/滚动懒加载/登录后操作/点击填表

关键差异：
- 不需要安装 `agent-browser`
- 不做 PID/端口级 kill
- 浏览器生命周期只通过 OpenClaw `browser start/stop` 管理（只关闭本次启动的隔离实例，不影响系统其它进程）

---

## Installation

### OpenClaw（推荐）

把 `openclaw-web-access/` 放到 OpenClaw 的 skills 目录（以你的部署为准，常见在 `~/.openclaw/workspace/skills/` 或 agent 的 skills 目录）。

> 这是“全局基础能力”，建议在 Capability Tree 中作为统一入口引用，避免各 Agent 各自实现联网策略。

### Claude Code（上游用法，保留）

```bash
git clone https://github.com/eze-is/eze-skills.git

# 复制需要的 skill 到 Claude Code 目录
cp -R eze-skills/daily-news ~/.claude/skills/
cp -R eze-skills/web-access ~/.claude/skills/

# web-access 首次使用需检查依赖
bash ~/.claude/skills/web-access/scripts/check-deps.sh
```

---

Upstream originally synced from `eze-skills-private` (per upstream README). Fork adds `openclaw-web-access`.
