# openclaw-web-access

OpenClaw 原生「联网访问入口」基础技能：统一 WebSearch / WebFetch / Browser 三种通道的选择与降级策略。

目标：**全局一致、最小权限、零外置依赖**（不需要 agent-browser / 不直接 kill 系统 Chrome）。

## 适用场景

- 搜索信息、查资料
- 读取网页内容（已知 URL）
- 访问动态渲染页面（SPA）
- 需要登录后操作
- 网页点击/填表
- 社交媒体/内容平台的浏览与抓取（优先走 Browser）

## 通道选择（OpenClaw 工具体系）

1) **搜索技能（技能树）**：作为搜索入口（例如 Exa/free 搜索 skill）；当 `web_search` 后端不可用时，应自动降级到该搜索 skill 或直接访问一手来源 URL。

2) **`web_fetch`**：已知 URL 的静态公开页面（低成本、快）。

3) **`browser`**：动态渲染/滚动懒加载/登录态/交互操作（点击、输入、选择）。

## 关键行为约束

- **禁止** PID/端口级 kill（例如 `kill -9` / `lsof -ti:9222 | xargs kill`）。
- 浏览器生命周期只通过 OpenClaw `browser start/stop` 管理：**启动了什么，就只关闭什么**，不影响系统其它进程/用户自己的 Chrome。

## 安装（OpenClaw）

把 `openclaw-web-access/` 目录放到 OpenClaw 的 skills 目录即可（以你的部署为准，常见在 `~/.openclaw/workspace/skills/` 或 agent 的 skills 目录）。

> 这是一个“全局基础能力”，建议在 Capability Tree 中作为统一入口引用，避免各 Agent 各自实现联网策略导致行为漂移。

---

来源：fork 自 https://github.com/eze-is/eze-skills （web-access 思路改写为 OpenClaw 工具体系版本）
