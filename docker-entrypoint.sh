#!/bin/bash

# InkOS Docker 入口点脚本

set -e

# 设置默认值
INKOS_DATA_DIR=${INKOS_DATA_DIR:-/data}
INKOS_CONFIG_DIR=${INKOS_CONFIG_DIR:-/data/config}
INKOS_LLM_PROVIDER=${INKOS_LLM_PROVIDER:-openai}
INKOS_LLM_BASE_URL=${INKOS_LLM_BASE_URL:-https://api.openai.com/v1}
INKOS_LLM_MODEL=${INKOS_LLM_MODEL:-gpt-4o}

# 创建必要目录
mkdir -p "$INKOS_DATA_DIR/books"
mkdir -p "$INKOS_CONFIG_DIR"

# 检查必要的环境变量
if [ -z "$INKOS_LLM_API_KEY" ]; then
    echo "警告: INKOS_LLM_API_KEY 未设置，InkOS 可能无法正常工作"
    echo "请通过环境变量或 .env 文件设置 API 密钥"
fi

# 初始化配置文件（如果不存在）
if [ ! -f "$INKOS_CONFIG_DIR/.env" ] && [ -n "$INKOS_LLM_API_KEY" ]; then
    cat > "$INKOS_CONFIG_DIR/.env" << EOF
INKOS_LLM_PROVIDER=$INKOS_LLM_PROVIDER
INKOS_LLM_BASE_URL=$INKOS_LLM_BASE_URL
INKOS_LLM_API_KEY=$INKOS_LLM_API_KEY
INKOS_LLM_MODEL=$INKOS_LLM_MODEL
INKOS_LLM_SERVICE=${INKOS_LLM_SERVICE:-}
INKOS_LLM_TEMPERATURE=${INKOS_LLM_TEMPERATURE:-0.7}
INKOS_DEFAULT_LANGUAGE=${INKOS_DEFAULT_LANGUAGE:-zh}
EOF
    echo "已创建配置文件: $INKOS_CONFIG_DIR/.env"
fi

# 设置环境变量
export INKOS_DATA_DIR
export INKOS_CONFIG_DIR
export PATH="/app/packages/cli/dist:$PATH"

# 检查是否有自定义命令
if [ $# -eq 0 ]; then
    # 默认启动 Studio
    echo "启动 InkOS Studio..."
    echo "数据目录: $INKOS_DATA_DIR"
    echo "配置目录: $INKOS_CONFIG_DIR"
    echo "LLM 提供商: $INKOS_LLM_PROVIDER"
    echo "LLM 模型: $INKOS_LLM_MODEL"
    echo "访问地址: http://localhost:4567"
    
    # 启动 Studio
    exec node packages/studio/dist/api/index.js
else
    # 执行传入的命令
    echo "执行命令: $@"
    exec "$@"
fi