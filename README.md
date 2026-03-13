# openclaw-web-access

OpenClaw 的「统一联网入口」技能。

它不提供某个特定网站的爬虫；它提供的是一套**稳定、可复用的上网策略**：在 **搜索（web_search）→ 抓取（web_fetch）→ 浏览器交互（browser）** 三条通道之间做一致的选择与升级/降级，避免不同 Agent 在联网时“用错通道、反复重试、登录态断掉”等问题。

设计目标：**全局一致、最小权限、零外置依赖**（不需要 agent-browser；不做 PID/端口级 kill）。

---

## 这仓库里有什么（结构）

本仓库只保留一个技能目录：

```
openclaw-web-access/     # 技能本体（SKILL.md）
README.md                # 你正在看的说明
```

把整个 `openclaw-web-access/` 放进 OpenClaw 的 skills 目录即可使用。

---

## 安装到 OpenClaw（推荐路径）

OpenClaw 常见 skills 目录：

- `~/.openclaw/workspace/skills/`

安装方式任选其一：

### A. 直接拷贝目录

```bash
git clone https://github.com/hjuyam/openclaw-web-access
cp -r openclaw-web-access/openclaw-web-access ~/.openclaw/workspace/skills/
```

### B. 作为子模块/软链接（便于更新）

```bash
git clone https://github.com/hjuyam/openclaw-web-access
ln -s $(pwd)/openclaw-web-access/openclaw-web-access ~/.openclaw/workspace/skills/openclaw-web-access
```

安装后重启/热加载方式取决于你的 OpenClaw 部署（有的会自动发现新技能；有的需要重启 gateway）。

---

## 它怎么“选通道”（路由规则）

按成本从低到高：

1) **web_search**（线索发现）
   - 适合：需要多来源线索、关键词、候选链接

2) **web_fetch**（已知 URL 的静态抓取）
   - 适合：公开页面、正文能直接抽取
   - 失败信号：403/空内容/明显依赖 JS 渲染 → **升级 browser**

3) **browser**（动态渲染/交互/登录）
   - 适合：SPA、懒加载滚动、点击/输入/选择、需要登录后才能看到内容
   - 内容平台/社交媒体（X/微博/小红书等）通常直接走 browser

**降级原则**：当 browser 控制不可用时，优先回退到 `web_fetch` 争取“够用的信息”；确实必须交互/登录的任务则提示用户修复 browser 控制（而不是无意义地重试）。

---

## 关键安全规则（必须遵守）

### 1) 不 kill 系统 Chrome

- **禁止** `kill -9` / 端口级 kill（例如 `lsof -ti:9222 | xargs kill`）
- 浏览器生命周期只通过 OpenClaw `browser start/stop` 管理：
  - **启动了什么，只关闭什么**；不影响系统里用户自己的 Chrome/Chromium

### 2) 不碰 cookie / 凭据文件

- **默认不读取、不写入**任何 cookies.json、浏览器 profile、导出的会话文件等
- 如需登录：只在确认为“未登录导致内容不可见”时，请用户在已打开浏览器窗口**手动登录**，然后继续同一 tab

### 3) 最小化访问

- 信息足够完成任务就停；优先给**一手来源链接**，避免为了“完整”而过度抓取

---

## Browser 的使用约定（你会在日志/行为里看到的）

- 默认使用隔离实例：`profile="openclaw"`
- 当用户明确提到 **Chrome 扩展 / Browser Relay / 接管现有标签页** 时，才用：`profile="chrome"`（需要用户在目标 tab 手动“附加/连接”）
- 常见交互流：
  1) `browser.open` / `browser.navigate`
  2) `browser.snapshot(refs="aria")`（拿到可点击/可输入的结构化引用）
  3) `browser.act`（click/type/select/press）
  4) 必要时 `browser.screenshot` 兜底

---

## 快速示例（适合照着念的）

### 示例 1：先搜，再读原文（web_search → web_fetch）

> “帮我找一下 OpenClaw browser 工具的 profile=chrome 是什么时候需要用的，并给出来源链接。”

期望行为：先 `web_search` 找到官方说明/仓库文档链接 → 对候选链接 `web_fetch` 抽取关键段落 → 给结论 + 一手来源。

### 示例 2：URL 已知但页面是 SPA（web_fetch 失败 → 升级 browser）

> “总结这篇文章的 5 个要点：<URL>。”

期望行为：先 `web_fetch`；若抽取为空或明显 JS 渲染 → 自动升级 `browser` 打开页面、滚动加载、再提炼要点。

### 示例 3：需要点击/筛选（直接 browser）

> “打开 <网站>，把筛选条件选成 ‘最近 7 天’ 和 ‘只看已完成’，然后把列表前 10 条标题给我。”

期望行为：直接 `browser`，用 snapshot+act 完成交互；不给 cookie 文件，不做任何 kill。

---

## 适用场景清单

- 搜索资料/核对信息（多来源）
- 已知 URL 的内容提取与摘要
- 动态渲染页面（SPA/懒加载）
- 需要登录后查看/操作（由用户手动登录）
- 网页点击/填表/选择器交互

---

## 来源与取舍（诚实说明）

思路 fork 自 https://github.com/eze-is/eze-skills （其中的 web-access 设计），并按 OpenClaw 工具体系（`web_search` / `web_fetch` / `browser`）改写与收敛。

与上游不同点：本技能**不引入** agent-browser，也**不通过** PID/端口级手段管理浏览器；完全依赖 OpenClaw 原生 `browser` 生命周期管理与结构化快照能力。
