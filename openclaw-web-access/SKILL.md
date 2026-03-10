---
name: openclaw-web-access
version: 0.3.0
author: hjuyam (forked from eze-is/eze-skills)
license: MIT
github: https://github.com/hjuyam/openclaw-web-access
description: |
  OpenClaw 原生「联网访问入口」基础技能：统一 WebSearch / WebFetch / Browser 三种通道的选择与降级策略。
  目标：全局一致、最小权限、零外置依赖（不需要 agent-browser / 不直接 kill 系统 Chrome）。

  触发场景：搜索信息、读取网页内容、访问动态渲染页面、需要登录后操作、网页点击/填表、社交媒体/内容平台抓取。
changelog:
  - version: 0.3.0
    date: 2026-03-10
    changes:
      - fork 版本：将 web-access 改写为 OpenClaw 工具体系（web_search/web_fetch/browser）
      - 移除 agent-browser/CDP 端口脚本与 PID kill 逻辑，改为 browser start/stop 生命周期
      - 搜索入口对接技能树中的“搜索技能”（优先 Exa/free；web_search 不可用时自动降级）
---

# openclaw-web-access

> 这是一个**全局基础能力**：建议在所有 Agent 的技能树里统一引用，避免各 Agent 各自实现“联网”导致行为漂移。

## 浏览哲学（像人一样浏览）

三句话：
1) **我需要什么**：先明确目标信息形态（搜答案/读原文/执行操作）。
2) **够了吗**：拿到足够完成任务的信息就停；不为“完整”付出不必要代价。
3) **遇到阻碍怎么办**：在同一层解决（弹窗/登录/懒加载/滚动），不要反复在不同工具间来回切。

## 通道选择（OpenClaw 原生工具）

| 场景 | 首选 | 何时升级 |
|---|---|---|
| 需要“搜索结果/线索发现” | **搜索技能（技能树）** | 搜不到一手来源 → 直接定位官网/原始 URL 再抓取 |
| 已知 URL，公开静态页面 | `web_fetch` | 403/空内容/明显 JS 渲染 → 升级到 `browser` |
| SPA/动态渲染/要滚动懒加载/要点按钮/要登录 | `browser` | 仅当 browser 控制不可用时才降级（见下） |

### 搜索入口的约定（对接“我们之前的搜索技能”）

- **优先**调用技能树里的搜索能力（例如 Exa/free 搜索 skill）。
- 如 `web_search` 后端鉴权异常/不可用：不要卡住，直接走上述搜索 skill 或改用已知来源 URL。

> 这条约定的目的：把“搜索后端”从 web-access 解耦出去，web-access 只负责路由与浏览策略。

## Browser 使用规范（不影响系统其它进程）

### 生命周期（关键要求）
- 只用 OpenClaw 的 `browser` 工具管理浏览器实例：
  - 启动：`browser(action="start", profile="openclaw")`
  - 结束：`browser(action="stop", profile="openclaw")`
- **禁止**任何 PID/端口级 kill（例如 `kill -9` / `lsof -ti:9222 | xargs kill`）。

这保证了：**任务启动了什么，就只关闭什么**，不会误伤系统里其它 Chrome/Chromium 进程。

### Profile 选择
- 默认：`profile="openclaw"`（隔离浏览器，适合自动化，风险可控）
- 当用户明确提到 Chrome 扩展 / Browser Relay / “接管我现有标签页”时：`profile="chrome"`（需要用户在目标 tab 点 Relay 附加）

### 推荐操作流
1) 打开/导航：`browser.open` / `browser.navigate`
2) 获取可操作结构：`browser.snapshot(refs="aria")`
3) 交互：`browser.act`（click/type/press/select）
4) 必要时视觉兜底：`browser.screenshot`

### 登录处理
- 先判断：**目标内容拿到了吗？**
- 只有确认“未登录导致目标内容缺失/不可见”时，才请用户在已打开的浏览器窗口中手动登录，然后继续同一 tab。

## Browser 控制不可用时（降级规则）

如果出现 browser 控制服务超时/不可达：
1) 先用 `web_fetch` 尝试拿到足够信息（若页面是静态的通常可行）。
2) 若任务必须交互/登录：提示用户重启 OpenClaw gateway 后再继续。

**不要**在不可用状态下反复重试 browser 工具（只会持续失败）。

## 输出与可验证性要求

- 给出一手来源链接（官网/原文/公告）。
- 简述通道选择原因（1-2 句即可）。
- 如信息不确定，明确不确定性与下一步验证路径。
