#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub仓库信息
REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/main"

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}服务器管理系统安装程序${NC}"
echo -e "${BLUE}=================================================${NC}"

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

# 静默下载所有文件
echo -e "${YELLOW}正在下载必要文件，请稍候...${NC}"

# 创建临时目录
mkdir -p /tmp/server-setup
cd /tmp/server-setup

# 尝试多种下载方法，但不显示详细信息
# 方法1: curl with User-Agent
curl -s -H "User-Agent: Mozilla/5.0" -o server_init.sh ${REPO_URL}/server_init.sh
curl -s -H "User-Agent: Mozilla/5.0" -o cleanup.sh ${REPO_URL}/cleanup.sh
curl -s -H "User-Agent: Mozilla/5.0" -o sb.sh ${REPO_URL}/sb.sh
curl -s -H "User-Agent: Mozilla/5.0" -o install_panel.sh ${REPO_URL}/install_panel.sh

# 如果方法1失败，尝试方法2
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    # 方法2: wget
    wget -q -O server_init.sh ${REPO_URL}/server_init.sh
    wget -q -O cleanup.sh ${REPO_URL}/cleanup.sh
    wget -q -O sb.sh ${REPO_URL}/sb.sh
    wget -q -O install_panel.sh ${REPO_URL}/install_panel.sh
fi

# 如果方法2失败，尝试方法3
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    # 方法3: 尝试不同的URL格式
    ALT_REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main"
    curl -s -o server_init.sh ${ALT_REPO_URL}/server_init.sh
    curl -s -o cleanup.sh ${ALT_REPO_URL}/cleanup.sh
    curl -s -o sb.sh ${ALT_REPO_URL}/sb.sh
    curl -s -o install_panel.sh ${ALT_REPO_URL}/install_panel.sh
fi

# 检查文件是否下载成功
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}文件下载失败，请检查网络连接或仓库地址${NC}"
    exit 1
fi

# 复制文件到正确位置
cp server_init.sh /root/
cp cleanup.sh /root/
cp sb.sh /usr/local/bin/
cp install_panel.sh /root/

# 设置执行权限
chmod +x /root/server_init.sh
chmod +x /root/cleanup.sh
chmod +x /usr/local/bin/sb.sh
chmod +x /root/install_panel.sh

# 创建sb命令链接
ln -sf /usr/local/bin/sb.sh /usr/local/bin/sb
chmod +x /usr/local/bin/sb

# 清理临时文件
cd ~
rm -rf /tmp/server-setup

echo -e "${GREEN}安装完成！正在启动服务器管理面板...${NC}"

# 直接启动SB面板
sb 