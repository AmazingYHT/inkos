# 多阶段构建 Dockerfile for InkOS
# 阶段 1: 构建
FROM node:22-bookworm-slim AS builder

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 package 文件
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./

# 复制 packages 目录
COPY packages/ ./packages/

# 复制其他必要文件
COPY .node-version .nvmrc ./

# 安装依赖
RUN pnpm install --frozen-lockfile

# 构建项目
RUN pnpm build

# 阶段 2: 生产环境
FROM node:22-bookworm-slim

# 设置工作目录
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 安装必要的系统工具
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -u 1000 inkos && chown -R inkos:inkos /app

# 切换到非 root 用户
USER inkos

# 复制 package 文件
COPY --from=builder --chown=inkos:inkos /app/package.json /app/pnpm-workspace.yaml /app/pnpm-lock.yaml ./

# 复制 packages 目录
COPY --from=builder --chown=inkos:inkos /app/packages/ ./packages/

# 复制构建产物
COPY --from=builder --chown=inkos:inkos /app/packages/core/dist/ ./packages/core/dist/
COPY --from=builder --chown=inkos:inkos /app/packages/cli/dist/ ./packages/cli/dist/
COPY --from=builder --chown=inkos:inkos /app/packages/studio/dist/ ./packages/studio/dist/

# 安装生产依赖
RUN pnpm install --prod --frozen-lockfile

# 创建数据目录
RUN mkdir -p /data/books /data/config && chown -R inkos:inkos /data

# 设置环境变量
ENV NODE_ENV=production
ENV INKOS_DATA_DIR=/data
ENV INKOS_CONFIG_DIR=/data/config

# 暴露端口
EXPOSE 4567
EXPOSE 4569

# 复制入口脚本
COPY --chown=inkos:inkos docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

# 设置入口点
ENTRYPOINT ["./docker-entrypoint.sh"]

# 默认命令
CMD ["inkos", "studio"]