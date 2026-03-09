#!/usr/bin/env bash
# 优雅关闭 agent-browser Chrome 实例（跨平台）
# 用法：bash close-browser.sh

CDP_PORT=9222
PROFILE_DIR="$HOME/.claude/browser-profile"

# 1. CDP Browser.close —— 协议层关闭，跨平台，Chrome 自己正常退出
# 用 Python 发 WebSocket 帧，不依赖外部包
python3 - <<'PYEOF' 2>/dev/null
import json, socket, base64, urllib.request, struct

try:
    # 获取 WebSocket 调试 URL
    data = json.loads(urllib.request.urlopen('http://localhost:9222/json/version', timeout=3).read())
    ws_url = data['webSocketDebuggerUrl']  # ws://localhost:9222/devtools/browser/uuid
    path = ws_url[len('ws://localhost:9222'):]

    # 建立 WebSocket 连接（手动握手，无需外部包）
    s = socket.socket()
    s.settimeout(5)
    s.connect(('localhost', 9222))
    key = base64.b64encode(b'claude-web-access!!').decode()
    s.send(f'GET {path} HTTP/1.1\r\nHost: localhost:9222\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n'.encode())
    s.recv(4096)  # 读取 HTTP 101 升级响应

    # 发送 Browser.close CDP 命令（RFC 6455 客户端帧，需要 mask）
    msg = json.dumps({"id": 1, "method": "Browser.close"}).encode()
    mask = bytes([0, 0, 0, 0])
    masked = bytes(b ^ mask[i % 4] for i, b in enumerate(msg))
    frame = bytes([0x81, 0x80 | len(msg)]) + mask + masked
    s.send(frame)
    s.close()
    print("Browser closed")
except Exception as e:
    print(f"CDP close failed: {e}", flush=True)
    exit(1)
PYEOF

# 2. 兜底：CDP 失败时按 OS 强制退出
if [ $? -ne 0 ]; then
  OS=$(uname -s)
  case "$OS" in
    Darwin)
      # macOS：osascript 优雅退出，避免"意外退出"弹窗
      OUR_PID=$(ps aux | grep "Google Chrome" | grep -- "--user-data-dir=${PROFILE_DIR}" | grep -v grep | awk '{print $2}' | head -1)
      [ -n "$OUR_PID" ] && osascript -e "tell application \"System Events\" to tell (first process whose unix id is ${OUR_PID}) to quit" 2>/dev/null && echo "Browser closed (osascript)"
      ;;
    Linux)
      # Linux：SIGTERM 即可，无弹窗问题
      OUR_PID=$(ps aux | grep "google-chrome\|chromium" | grep -- "--user-data-dir=${PROFILE_DIR}" | grep -v grep | awk '{print $2}' | head -1)
      [ -n "$OUR_PID" ] && kill "$OUR_PID" 2>/dev/null && echo "Browser closed (SIGTERM)"
      ;;
    *)
      echo "Unsupported OS: $OS — please close the browser manually"
      ;;
  esac
fi
