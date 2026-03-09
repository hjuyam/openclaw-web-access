#!/usr/bin/env bash
# web-access skill 依赖检查与安装
# 用法：bash setup.sh

# 不用 set -e，手动控制每步，确保用户看到完整报告
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OK="✓"
FAIL="✗"
WARN="!"
ALL_OK=true

echo "=== web-access skill 依赖检查 ==="
echo ""

# 1. macOS 检查（Chrome 启动路径写死了 macOS，浏览器模式仅支持 macOS）
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "$FAIL 当前仅支持 macOS（Chrome 启动路径依赖 /Applications/Google Chrome.app）"
  ALL_OK=false
else
  echo "$OK macOS"
fi

# 2. Google Chrome
if [ -f "$CHROME" ]; then
  echo "$OK Google Chrome"
else
  echo "$FAIL Google Chrome 未安装，请从 https://www.google.com/chrome 下载安装"
  ALL_OK=false
fi

# 3. curl
if command -v curl &>/dev/null; then
  echo "$OK curl"
else
  echo "$FAIL curl 未找到（通常 macOS 内置，请检查系统）"
  ALL_OK=false
fi

# 4. python3
if command -v python3 &>/dev/null; then
  echo "$OK python3"
else
  echo "$FAIL python3 未找到（通常 macOS 内置，请检查系统）"
  ALL_OK=false
fi

# 5. Node.js / npm
# bash 直接调用时不会 source shell profile，fnm/nvm 管理的 node 不在 PATH
# 主动探测常见安装路径
find_npm() {
  # 优先用 PATH 里的
  if command -v npm &>/dev/null; then
    echo "$(command -v npm)"
    return
  fi
  # fnm 常见路径
  local fnm_npm="$HOME/.local/share/fnm/aliases/default/bin/npm"
  [ -f "$fnm_npm" ] && echo "$fnm_npm" && return
  # nvm 常见路径
  local nvm_npm="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node 2>/dev/null | sort -V | tail -1)/bin/npm"
  [ -f "$nvm_npm" ] && echo "$nvm_npm" && return
  # Homebrew
  [ -f "/opt/homebrew/bin/npm" ] && echo "/opt/homebrew/bin/npm" && return
  [ -f "/usr/local/bin/npm" ] && echo "/usr/local/bin/npm" && return
  echo ""
}

NPM_PATH=$(find_npm)
if [ -n "$NPM_PATH" ]; then
  NODE_VER=$("$NPM_PATH" exec -- node --version 2>/dev/null || node --version 2>/dev/null || echo "unknown")
  echo "$OK Node.js $NODE_VER  (npm: $NPM_PATH)"
else
  echo "$FAIL Node.js / npm 未找到"
  echo "   推荐：brew install fnm && fnm install --lts && fnm default lts-latest"
  echo "   或直接安装：https://nodejs.org"
  ALL_OK=false
fi

# 6. agent-browser
find_agent_browser() {
  command -v agent-browser 2>/dev/null && return
  # 从 npm 全局 bin 目录找
  if [ -n "$NPM_PATH" ]; then
    local npm_bin_dir
    npm_bin_dir=$(dirname "$NPM_PATH")
    [ -f "$npm_bin_dir/agent-browser" ] && echo "$npm_bin_dir/agent-browser" && return
  fi
  echo ""
}

AB_PATH=$(find_agent_browser)
if [ -n "$AB_PATH" ]; then
  AB_VER=$("$AB_PATH" --version 2>/dev/null || echo "unknown")
  echo "$OK agent-browser $AB_VER"
elif [ -n "$NPM_PATH" ]; then
  echo "$WARN agent-browser 未安装，正在安装..."
  if "$NPM_PATH" install -g agent-browser 2>&1; then
    # 安装后重新探测（PATH 可能还未更新）
    AB_PATH=$(find_agent_browser)
    if [ -n "$AB_PATH" ]; then
      AB_VER=$("$AB_PATH" --version 2>/dev/null || echo "unknown")
      echo "$OK agent-browser $AB_VER（已安装）"
    else
      # 安装成功但 PATH 未刷新，提示用户重开终端
      echo "$WARN agent-browser 已安装，但当前 shell PATH 未刷新"
      echo "   请重新打开终端后再试，或手动运行："
      echo "   $("$NPM_PATH" prefix -g 2>/dev/null)/bin/agent-browser --version"
    fi
  else
    echo "$FAIL agent-browser 安装失败"
    echo "   如遇权限问题，请尝试：sudo $NPM_PATH install -g agent-browser"
    echo "   或配置 npm 全局路径到用户目录（无需 sudo）"
    ALL_OK=false
  fi
else
  echo "$FAIL agent-browser 未安装（需先安装 Node.js）"
  ALL_OK=false
fi

echo ""
if $ALL_OK; then
  echo "=== 所有依赖就绪，可以使用 web-access skill ==="
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  web-access 工作原理（快速了解）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "│ AI 访问网页时，按代价从低到高自动选择方式："
  echo "│"
  echo "│   1. 直接搜索   → 只需要关键词/摘要，最省"
  echo "│   2. 抓取页面   → 读公开静态页面，不启动浏览器"
  echo "│   3. 真实浏览器 → 需要登录或动态页面时才启动"
  echo "│"
  echo "│ 能用轻的就不用重的，速度更快、消耗更少。"
  echo ""
  echo "─────────────────────────────────────────────────────"
  echo ""
  echo "│ 浏览器模式的两个关键设计："
  echo "│"
  echo "│ · 登录态持久"
  echo "│   在弹出的 Chrome 窗口登录一次，下次直接复用。"
  echo "│   独立 profile，不动你自己的 Chrome。"
  echo "│"
  echo "│ · 读结构不截图"
  echo "│   AI 读页面文字结构而非截图，速度快、token 少。"
  echo "│   只有图片里有关键信息时才看图。"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  凡是涉及联网的任务，直接说需求即可。"
  echo "  AI 会自动选最合适的方式帮你获取内容。"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "=== 请解决上述问题后重新运行此脚本 ==="
  exit 1
fi
