# 多阶段构建 - Flutter Web 前端 Dockerfile
# 阶段1: 构建 Flutter Web 应用
FROM ghcr.io/cirruslabs/flutter:stable AS build

# 设置工作目录
WORKDIR /app

# 复制 pubspec 文件
COPY pubspec.yaml pubspec.lock ./

# 获取依赖（使用国内镜像加速，可选）
# RUN flutter pub get --verbose
RUN flutter pub get

# 复制源代码
COPY . .

# 启用 Web 支持
RUN flutter config --enable-web

# 构建 Web 应用（release 模式）
# 使用 canvaskit 渲染器以获得更好的性能
RUN flutter build web --release --web-renderer canvaskit

# 阶段2: 使用 Nginx 提供静态文件
FROM nginx:alpine

# 复制构建产物到 Nginx 目录
COPY --from=build /app/build/web /usr/share/nginx/html

# 复制自定义 Nginx 配置
# 如果 nginx.conf 存在则使用，否则使用默认配置
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 健康检查（使用 wget，如果不存在则安装）
RUN apk add --no-cache wget || true
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
