#!/usr/bin/env bash
# 环境探测 - 输出依赖状态供 AI 判断和处理

echo "=== web-access 环境探测 ==="
echo ""
echo "OS:           $(uname -s) $(uname -m)"
echo "Shell:        $SHELL"
echo ""

# Chrome（macOS 标准路径）
CHROME_MAC="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ -f "$CHROME_MAC" ]; then
  echo "chrome:       found ($CHROME_MAC)"
else
  echo "chrome:       missing"
fi

# curl
echo "curl:         $(command -v curl 2>/dev/null || echo 'missing')"

# python3
echo "python3:      $(command -v python3 2>/dev/null || echo 'missing')"

# node
NODE_PATH=$(command -v node 2>/dev/null)
if [ -n "$NODE_PATH" ]; then
  echo "node:         $NODE_PATH ($(node --version 2>/dev/null))"
else
  echo "node:         missing"
fi

# npm
NPM_PATH=$(command -v npm 2>/dev/null)
if [ -n "$NPM_PATH" ]; then
  echo "npm:          $NPM_PATH"
  echo "npm_global:   $(npm prefix -g 2>/dev/null)/bin"
else
  echo "npm:          missing"
fi

# agent-browser
AB_PATH=$(command -v agent-browser 2>/dev/null)
if [ -n "$AB_PATH" ]; then
  echo "agent-browser: $AB_PATH ($(agent-browser --version 2>/dev/null))"
else
  echo "agent-browser: missing"
fi

# osascript（macOS 优雅退出浏览器依赖）
echo "osascript:    $(command -v osascript 2>/dev/null || echo 'missing')"

echo ""
echo "=== 探测完成，等待 AI 处理 ==="
