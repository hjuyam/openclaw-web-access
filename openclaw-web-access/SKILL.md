---
name: openclaw-web-access
version: 0.3.2
author: hjuyam (forked from eze-is/eze-skills)
license: MIT
github: https://github.com/hjuyam/openclaw-web-access
description: |
  OpenClaw 原生「联网访问入口」基础技能：统一 WebSearch / WebFetch / Browser 三种通道的选择与降级策略。
  目标：全局一致、最小权限、零外置依赖（不需要 agent-browser / 不直接 kill 系统 Chrome）。

  触发场景：搜索信息、读取网页内容、访问动态渲染页面、需要登录后操作、网页点击/填表、社交媒体/内容平台抓取。
triggers:
  - 搜索
  - 查资料
  - 打开网页
  - 抓取网页
  - 动态页面
  - 需要登录
  - 点按钮/填表
  - 社交媒体
changelog:
  - version: 0.3.2
    date: 2026-03-13
    changes:
      - 增强：加入 TL;DR 作战版、硬禁止项（不碰 cookie/凭据文件）、统一对用户的输出模板
      - 治理：作为唯一“联网访问入口”技能，承接触发/路由收口
  - version: 0.3.1
    date: 2026-03-10
    changes:
      - 文档更新：移除“技能树”相关表述（该概念仅部分部署存在）
      - 搜索入口改为通用描述：优先 web_search；不可用时走部署环境提供的备用搜索后端（例如 Exa/MCP），或直接访问一手来源
---

# openclaw-web-access

> 这是一个**全局基础能力**：用于标准化“联网访问入口”，避免各 Agent 各自实现联网策略导致行为漂移。

## TL;DR（30 秒作战版）

**选通道：**
- 需要线索/多来源 → `web_search`
- 已知 URL 且静态 → `web_fetch`
- SPA/要滚动/要点按钮/要登录 → `browser`

**三条硬规则：**
1) 信息够用就停（不为“完整”而完整）。
2) 只要能给出一手来源，就给一手来源。
3) **绝不 kill 系统 Chrome；绝不读写 cookie/凭据文件。**

## 禁止项（Hard MUST NOT）

- MUST NOT：为了实现浏览器能力去 `kill -9` / 端口级 kill 任何系统 Chrome/Chromium。
- MUST NOT：读写用户的 cookie/凭据文件（包含但不限于 cookies.json、浏览器 profile）。
  - 例外：仅当用户明确授权、明确给出文件路径与用途，且能说明风险时才可以；否则一律不做。

## 浏览哲学（像人一样浏览）

三句话：
1) **我需要什么**：先明确目标信息形态（搜答案/读原文/执行操作）。
2) **够了吗**：拿到足够完成任务的信息就停；不为“完整”付出不必要代价。
3) **遇到阻碍怎么办**：在同一层解决（弹窗/登录/懒加载/滚动），不要反复在不同工具间来回切。

## 通道选择（OpenClaw 原生工具）

| 场景 | 首选 | 何时升级 |
|---|---|---|
| 需要“搜索结果/线索发现” | `web_search`（或部署环境提供的备用搜索后端） | 搜不到一手来源 → 直接定位官网/原始 URL 再抓取 |
| 已知 URL，公开静态页面 | `web_fetch` | 403/空内容/明显 JS 渲染 → 升级到 `browser` |
| SPA/动态渲染/要滚动懒加载/要点按钮/要登录 | `browser` | 仅当 browser 控制不可用时才降级（见下） |

### 搜索入口约定（通用版）

- **优先**使用 `web_search` 做线索发现。
- 如 `web_search` 后端鉴权异常/不可用：不要卡住，改用你部署环境里提供的备用搜索后端（例如 Exa/MCP 搜索），或直接访问已知的一手来源 URL。

> 目的：把“搜索后端”从本技能解耦出去，本技能只负责路由与浏览策略。

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

## 对用户的输出模板（强制）

- **通道选择**：我使用了 `<web_search|web_fetch|browser>`，因为 `<原因一句话>`。
- **一手来源**：<链接1>（必要时 <链接2>）
- **结论**：<3-7 行，信息密度优先>
- **不确定性/下一步**（若有）：<如何验证/下一步操作>
