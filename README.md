# openclaw-web-access

Claude Code 原生有联网能力，但在不同任务里容易出现“用错通道 / 降级不稳定 / 登录态不连续”等问题。

**openclaw-web-access** 把这套“联网访问入口”在 OpenClaw 里标准化：统一 **搜索 → 抓取 → 浏览器交互** 的升级路径，并贯彻“像人一样浏览”的理念：带着目标进入，边看边判断，遇到阻碍在层内解决，尽量不打扰用户。

目标：**全局一致、最小权限、零外置依赖**（不需要 agent-browser / 不直接 kill 系统 Chrome）。

## 适用场景

- 搜索信息、查资料（需要多来源线索）
- 读取网页内容（已知 URL）
- 访问动态渲染页面（SPA）
- 需要登录后操作
- 网页点击/填表
- 社交媒体/内容平台的浏览与抓取（通常应直接走 Browser）

## 通道选择（OpenClaw 工具体系）

遇到联网任务时，按代价从低到高选择方式：

1) **WebSearch**（`web_search` 或你环境中的备用搜索后端）
   - 只需要搜索结果/关键词线索时用
   - **降级**：当 `web_search` 后端鉴权不可用时，改用你环境里已配置的备用搜索能力（例如 Exa/MCP 搜索），或直接访问已知的一手来源 URL

2) **WebFetch**（`web_fetch`）
   - URL 已知、公开静态页面优先
   - 失败信号（空内容/403/明显 JS 渲染）→ 升级 Browser

3) **Browser**（`browser`）
   - 动态渲染/滚动懒加载/登录态/交互操作（点击、输入、选择）
   - 社交媒体/内容平台（微博/小红书/X 等）一般直接进入这一层，跳过 WebFetch

## 关键行为约束（重要）

- **禁止** PID/端口级 kill（例如 `kill -9` / `lsof -ti:9222 | xargs kill`）。
- 浏览器生命周期只通过 OpenClaw `browser start/stop` 管理：**启动了什么，就只关闭什么**，不影响系统其它进程/用户自己的 Chrome。
- 登录策略：只有当确认“目标内容拿不到且登录可解锁”时，才提示用户在已打开的浏览器窗口手动登录；登录后继续同一 tab。

## 安装（OpenClaw）

把 `openclaw-web-access/` 目录放到 OpenClaw 的 skills 目录即可（以你的部署为准，常见在 `~/.openclaw/workspace/skills/` 或 agent 的 skills 目录）。

---

来源：fork 自 https://github.com/eze-is/eze-skills ，并将其中的 web-access 思路按 OpenClaw 工具体系（web_search/web_fetch/browser）改写与收敛。
