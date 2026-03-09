#!/usr/bin/env bash
# Chrome CDP 生命周期管理（始终 headed 模式）
# 用法：bash ensure-browser.sh

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CDP_PORT=9222
PROFILE_DIR="$HOME/.claude/browser-profile"

# 检测 CDP 端口是否已就绪
check_ready() {
  curl -s "http://localhost:${CDP_PORT}/json/version" >/dev/null 2>&1
}

# 检测当前运行的 Chrome 是否使用了正确的 profile
check_profile() {
  ps aux | grep -E "Google Chrome" | grep -- "--user-data-dir=${PROFILE_DIR}" | grep -v grep >/dev/null 2>&1
}

if check_ready; then
  if check_profile; then
    echo "already running"
    exit 0
  else
    # 端口被占用但不是我们的 Chrome，报错退出，不动用户的浏览器
    echo "ERROR: Port ${CDP_PORT} is in use by another process. Please free the port manually." >&2
    exit 1
  fi
fi

# 如果有我们自己的 Chrome 残留（有 profile 但没监听端口），清理掉
OUR_PID=$(ps aux | grep "Google Chrome" | grep -- "--user-data-dir=${PROFILE_DIR}" | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$OUR_PID" ]; then
  osascript -e "tell application \"System Events\" to tell (first process whose unix id is ${OUR_PID}) to quit" 2>/dev/null || kill "$OUR_PID" 2>/dev/null
  sleep 1
fi

# 启动 Chrome（后台，始终 headed）
"$CHROME" \
  "--remote-debugging-port=${CDP_PORT}" \
  "--user-data-dir=${PROFILE_DIR}" \
  "--no-first-run" \
  "--no-default-browser-check" \
  "--exclude-switches=enable-automation" \
  "--disable-infobars" \
  >/dev/null 2>&1 &

# 等待 CDP 就绪（最多 15 秒）
for i in $(seq 1 30); do
  if check_ready; then
    echo "Browser ready on port ${CDP_PORT}"
    exit 0
  fi
  sleep 0.5
done

echo "ERROR: Browser failed to start within 15 seconds" >&2
exit 1
