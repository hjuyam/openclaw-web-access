---
name: web-access
version: 1.0.0
author: 一泽Eze
license: MIT
github: https://github.com/eze-is-1/eze-skills
description: |
  所有联网操作必须通过此 skill 处理，包括：搜索、网页抓取、登录后操作、动态页面交互等。
  触发场景：用户要求搜索信息、查看网页内容、访问需要登录的网站、操作网页界面、抓取社交媒体内容（小红书、微博、推特等）、读取动态渲染页面、以及任何需要真实浏览器环境的网络任务。
---

# web-access Skill

## 首次安装

用户首次使用时，执行以下流程：

**Step 1：运行环境探测**
```bash
bash ~/.claude/skills/web-access/scripts/check-deps.sh
```

**Step 2：AI 根据输出处理缺失依赖**

探测脚本只报告事实，安装决策由 AI 完成：
- 读取 OS 类型，选择对应的安装方式
- `agent-browser` 缺失 → `npm install -g agent-browser`（需先有 Node.js）
- Node.js 缺失 → 根据 OS 给出安装建议（macOS: `brew install fnm && fnm install --lts`）
- Chrome 缺失 → 提示用户手动下载（无法自动安装）
- `osascript` 缺失（非 macOS）→ 无影响，close-browser.sh 首选 CDP Browser.close（跨平台），osascript 只是 macOS 兜底
- npm 在 PATH 里找不到但系统已装（fnm/nvm 场景）→ 用绝对路径执行安装

**Step 3：安装完成后输出 onboarding 说明**
```bash
bash ~/.claude/skills/web-access/scripts/setup.sh
```

## 核心理念

网页信息通过多种通道存在：搜索摘要、静态文字、动态渲染内容、图片承载的内容。**每种通道的获取代价不同，信息覆盖范围不同。** 目标始终是：以最低代价获取完整的相关信息。

这意味着不要用重型工具做轻量任务，也不要用轻量工具面对它覆盖不到的内容——尤其是图片。

## 感知通道选择

从轻到重依次尝试，能解决就停：

**WebSearch** — 只需要摘要或关键词结果时使用。不需要加载完整页面。

**WebFetch** — 读取静态公开页面。失败（空内容 / 403 / JS 渲染）时升级到浏览器层。请求时加 header `Accept: text/markdown, text/html`，支持该协议的网站会直接返回 Markdown，省约 80% token。

**浏览器 CDP 模式** — 需要登录态、交互操作、动态渲染，或 WebFetch 失败时使用。

进入浏览器层后，进一步区分任务性质：

- **操作型**（导航、填表、点击）：用 accessibility tree 感知界面，遇到无法识别的元素时才截图辅助
- **内容型**（读帖子、看资讯、分析页面）：accessibility tree 读文字结构，同时主动判断图片是否承载核心信息——如果是，提取图片 URL 定向读取

**关于图片的判断原则**：图片不总是需要读，但在内容型页面里，图片往往是信息本身而非装饰。社交媒体、图文博客、截图类内容，默认假设图片有价值，主动去取；工具类、导航类页面，默认 accessibility tree 够用。

## 浏览器 CDP 模式

### 启动

```bash
bash ~/.claude/skills/web-access/scripts/ensure-browser.sh
```

- `already running` → 直接用（任务结束后不关闭）
- `Browser ready on port 9222` → 就绪（任务结束后关闭）
- `ERROR` 或 agent-browser 无响应 → 执行 `bash ~/.claude/skills/web-access/scripts/close-browser.sh` 后重新运行

> **⚠️ 严禁降级**：只用 agent-browser CDP 模式，不切换到 playwright MCP 或其他浏览器工具。降级会丢失持久化登录态，且绕过 headed 反爬机制。

### 常用命令

```bash
agent-browser --cdp 9222 open <url>           # 打开页面
agent-browser --cdp 9222 snapshot -i          # 可交互元素（操作用）
agent-browser --cdp 9222 snapshot             # 完整无障碍树（读文字用）
agent-browser --cdp 9222 click @ref-123       # 点击元素
agent-browser --cdp 9222 fill @ref-123 "内容" # 填写输入框
agent-browser --cdp 9222 wait load networkidle
agent-browser --cdp 9222 scroll down 3000     # 触发懒加载
agent-browser --cdp 9222 screenshot /tmp/x.png
agent-browser --cdp 9222 eval "<js>"          # 执行 JS，用于提取 DOM 信息
```

### 图片提取

判断内容在图片里时，用 `eval` 从 DOM 直接拿图片 URL，再定向打开截图读取——比全页截图精准得多。

需要知道的两个技术细节：
- **懒加载**：未进入视口的图片 `naturalWidth` 为 0，eval 前先 scroll 到底才能拿到完整列表
- **过滤噪声**：`naturalWidth > 200` 排除图标和头像，留下内容图

```bash
agent-browser --cdp 9222 scroll down 3000
agent-browser --cdp 9222 eval "JSON.stringify(Array.from(document.querySelectorAll('img')).map((img,i)=>({i,src:img.src,w:img.naturalWidth,h:img.naturalHeight})).filter(x=>x.w>200))"
# 对每张目标图片：
agent-browser --cdp 9222 open <img_url>
agent-browser --cdp 9222 screenshot /tmp/img_n.png
# 用 Read tool 读取截图内容
```

### 登录检测

`snapshot -i` 后出现密码框、`/login` URL、"请登录"提示时，告知用户在已弹出的 Chrome 窗口完成登录，确认后继续，无需重启浏览器。

### 任务结束

ensure-browser.sh 返回 `Browser ready`（本次启动）→ 关闭浏览器（**必须用此脚本，勿直接 kill，否则会留下崩溃窗口**）：
```bash
bash ~/.claude/skills/web-access/scripts/close-browser.sh
```

## References 索引

| 文件 | 何时加载 |
|------|---------|
| `references/commands.md` | 需要不常用命令时（drag、storage、pdf 等） |
| `references/login-flow.md` | 需要了解登录流程细节时 |
