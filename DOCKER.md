# InkOS Docker 部署指南

## 概述

InkOS 支持通过 Docker 进行容器化部署，提供两种运行模式：
1. **Studio 模式** - Web 工作台，适合交互式写作
2. **Daemon 模式** - 守护进程，适合自动写作

## 快速开始

### 1. 克隆仓库并切换分支

```bash
git clone https://github.com/AmazingYHT/inkos.git
cd inkos
git checkout master-docker
```

### 2. 配置环境变量

复制环境配置文件并填入你的 API 密钥：

```bash
cp .env.docker.example .env
# 编辑 .env 文件，填入你的 LLM API 密钥
```

### 3. 启动服务

#### 使用 Docker Compose（推荐）

```bash
# 启动 Studio
docker-compose up inkos

# 启动 Studio + Daemon
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

#### 使用 Docker 命令

```bash
# 构建镜像
docker build -t inkos .

# 运行 Studio
docker run -d \
  --name inkos-studio \
  -p 4567:4567 \
  -p 4569:4569 \
  -v inkos-data:/data \
  -v ./books:/data/books \
  -v ./config:/data/config \
  -e INKOS_LLM_PROVIDER=openai \
  -e INKOS_LLM_BASE_URL=https://api.openai.com/v1 \
  -e INKOS_LLM_API_KEY=sk-your-key \
  -e INKOS_LLM_MODEL=gpt-4o \
  inkos

# 运行 Daemon
docker run -d \
  --name inkos-daemon \
  -v inkos-data:/data \
  -v ./books:/data/books \
  -v ./config:/data/config \
  -e INKOS_LLM_PROVIDER=openai \
  -e INKOS_LLM_BASE_URL=https://api.openai.com/v1 \
  -e INKOS_LLM_API_KEY=sk-your-key \
  -e INKOS_LLM_MODEL=gpt-4o \
  inkos inkos up --log inkos.log
```

## 配置说明

### 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| `INKOS_LLM_PROVIDER` | 否 | `openai` | LLM 提供商 |
| `INKOS_LLM_BASE_URL` | 否 | `https://api.openai.com/v1` | API 地址 |
| `INKOS_LLM_API_KEY` | 是 | - | API 密钥 |
| `INKOS_LLM_MODEL` | 否 | `gpt-4o` | 模型名称 |
| `INKOS_LLM_SERVICE` | 否 | - | 服务名称（自动推导） |
| `INKOS_LLM_TEMPERATURE` | 否 | `0.7` | 温度参数 |
| `INKOS_DEFAULT_LANGUAGE` | 否 | `zh` | 默认语言 |

### 端口配置

| 端口 | 用途 |
|------|------|
| `4567` | Studio Web 界面 |
| `4569` | Studio API 接口 |

### 数据卷

| 卷名 | 用途 |
|------|------|
| `inkos-data` | 持久化数据 |
| `./books` | 书籍文件 |
| `./config` | 配置文件 |

## 使用示例

### 1. 创建新书

```bash
# 通过 Docker 执行命令
docker exec inkos-studio inkos book create --title "我的第一本小说" --genre xuanhuan
```

### 2. 开始写作

```bash
# 写下一章
docker exec inkos-studio inkos write next "我的第一本小说"

# 查看状态
docker exec inkos-studio inkos status
```

### 3. 访问 Web 界面

打开浏览器访问：http://localhost:4567

### 4. 导出书籍

```bash
# 导出为 EPUB
docker exec inkos-studio inkos export "我的第一本小说" --format epub

# 导出为 Markdown
docker exec inkos-studio inkos export "我的第一本小说"
```

## 高级配置

### 使用自定义 LLM 服务

```bash
# 使用 Moonshot
docker run -d \
  --name inkos \
  -p 4567:4567 \
  -e INKOS_LLM_PROVIDER=custom \
  -e INKOS_LLM_BASE_URL=https://api.moonshot.cn/v1 \
  -e INKOS_LLM_API_KEY=sk-your-moonshot-key \
  -e INKOS_LLM_MODEL=kimi-k2.5 \
  -e INKOS_LLM_SERVICE=moonshot \
  inkos

# 使用 Google Gemini
docker run -d \
  --name inkos \
  -p 4567:4567 \
  -e INKOS_LLM_PROVIDER=google \
  -e INKOS_LLM_API_KEY=your-gemini-key \
  -e INKOS_LLM_MODEL=gemini-2.5-flash \
  inkos
```

### 多模型路由配置

创建 `config/inkos.json`：

```json
{
  "models": {
    "writer": {
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20241022",
      "apiKeyEnv": "ANTHROPIC_API_KEY"
    },
    "auditor": {
      "provider": "openai",
      "model": "gpt-4o",
      "apiKeyEnv": "OPENAI_API_KEY"
    }
  }
}
```

### 配置代理

如果需要通过代理访问 API：

```bash
docker run -d \
  --name inkos \
  -p 4567:4567 \
  -e HTTP_PROXY=http://host.docker.internal:7890 \
  -e HTTPS_PROXY=http://host.docker.internal:7890 \
  inkos
```

## 故障排除

### 1. 权限问题

```bash
# 确保目录权限正确
sudo chown -R 1000:1000 ./books ./config
```

### 2. 端口冲突

```bash
# 检查端口占用
netstat -tulpn | grep :4567

# 修改端口映射
docker run -d -p 8080:4567 -p 8081:4569 inkos
```

### 3. 日志查看

```bash
# 查看容器日志
docker logs inkos-studio

# 实时查看日志
docker logs -f inkos-studio

# 查看 Daemon 日志
docker exec inkos-daemon tail -f /data/inkos.log
```

### 4. 健康检查

```bash
# 检查容器状态
docker ps

# 检查服务健康状态
curl http://localhost:4567/health
```

## 生产环境部署

### 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name inkos.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:4567;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api {
        proxy_pass http://localhost:4569;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 使用 Docker Swarm

```bash
# 初始化 Swarm
docker swarm init

# 部署服务
docker stack deploy -c docker-compose.yml inkos
```

### 使用 Kubernetes

参考 `k8s/` 目录下的配置文件（如果提供）。

## 更新升级

```bash
# 拉取最新代码
git pull origin master-docker

# 重新构建镜像
docker build -t inkos:latest .

# 重启服务
docker-compose down
docker-compose up -d
```

## 备份与恢复

### 备份数据

```bash
# 备份书籍和配置
tar -czf inkos-backup-$(date +%Y%m%d).tar.gz ./books ./config

# 备份 Docker 卷
docker run --rm -v inkos-data:/data -v $(pwd):/backup alpine \
  tar -czf /backup/inkos-volume-backup.tar.gz -C /data .
```

### 恢复数据

```bash
# 恢复书籍和配置
tar -xzf inkos-backup-20260508.tar.gz

# 恢复 Docker 卷
docker run --rm -v inkos-data:/data -v $(pwd):/backup alpine \
  tar -xzf /backup/inkos-volume-backup.tar.gz -C /data
```

## 支持

- 项目地址: https://github.com/AmazingYHT/inkos
- 文档: https://github.com/AmazingYHT/inkos/blob/master/README.md
- 问题反馈: https://github.com/AmazingYHT/inkos/issues