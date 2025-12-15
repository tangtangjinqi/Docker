# 改用Docker Hub官方Ubuntu 24.04镜像（ACR可直接拉取，无权限问题）
FROM registry.aliyuncs.com/ubuntu/24.04:latest

# 关键：关闭交互安装（避免ACR构建时tzdata/nginx安装卡住）
ENV DEBIAN_FRONTEND=noninteractive
# 配置国内时区
ENV TZ=Asia/Shanghai

# 替换Ubuntu 24.04为阿里云源（加速apt安装nginx，避免超时）
RUN sed -i.bak \
    -e 's@//archive.ubuntu.com/@//mirrors.aliyun.com/@g' \
    -e 's@//security.ubuntu.com/@//mirrors.aliyun.com/@g' \
    /etc/apt/sources.list && \
    # 更新源 + 安装nginx（合并命令减少镜像层）
    apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    # 清理缓存（减少镜像体积）
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin

# 复制静态页面到Nginx默认目录（确保index.html存在于GitHub仓库根目录）
COPY index.html /var/www/html/

# 修复Nginx权限（Ubuntu 24.04严格管控权限，避免容器启动失败）
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    # 创建Nginx运行目录（避免启动报错）
    mkdir -p /var/run/nginx && \
    chown -R www-data:www-data /var/run/nginx

# 暴露80端口
EXPOSE 80

# 启动Nginx（前台运行，避免容器退出）
USER www-data
CMD ["nginx", "-g", "daemon off;"]
