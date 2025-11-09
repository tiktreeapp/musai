#!/bin/bash

# Render服务唤醒脚本
WAKE_URL="https://musai-backend.onrender.com/health"

echo "🚀 开始唤醒 Render 服务: $WAKE_URL"
max_attempts=15
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "⏳ 尝试第 $attempt 次..."
    
    # 使用curl请求，设置5秒超时
    if curl -s -f -m 5 "$WAKE_URL" > /dev/null 2>&1; then
        echo "✅ Render服务已唤醒 (尝试 $attempt 次)"
        exit 0
    else
        echo "⚠️ 第 $attempt 次连接失败"
    fi
    
    # 等待5秒
    sleep 5
    attempt=$((attempt + 1))
done

echo "❌ 尝试 $max_attempts 次后仍无法唤醒 Render 服务"
exit 1