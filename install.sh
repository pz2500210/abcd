#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub仓库信息
REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/main"

# 显示欢迎信息
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}服务器管理系统一键安装脚本${NC}"
echo -e "${BLUE}=================================================${NC}"

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

# 下载所有必要文件
echo -e "${YELLOW}下载必要文件...${NC}"
curl -s -o /root/server_init.sh ${REPO_URL}/server_init.sh
curl -s -o /root/cleanup.sh ${REPO_URL}/cleanup.sh
curl -s -o /usr/local/bin/sb.sh ${REPO_URL}/sb.sh
curl -s -o /root/install_panel.sh ${REPO_URL}/install_panel.sh

# 设置执行权限
chmod +x /root/server_init.sh
chmod +x /root/cleanup.sh
chmod +x /usr/local/bin/sb.sh
chmod +x /root/install_panel.sh

# 创建sb命令链接
ln -sf /usr/local/bin/sb.sh /usr/local/bin/sb
chmod +x /usr/local/bin/sb

echo -e "${GREEN}所有文件下载完成!${NC}"

# 询问是否立即初始化服务器
echo -e "${YELLOW}是否立即初始化服务器? (y/n)${NC}"
read -p "选择 [y/n]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}开始初始化服务器...${NC}"
    bash /root/server_init.sh
else
    echo -e "${YELLOW}您可以稍后运行以下命令初始化服务器:${NC}"
    echo -e "${GREEN}bash /root/server_init.sh${NC}"
    echo -e "${YELLOW}或者运行以下命令启动管理面板:${NC}"
    echo -e "${GREEN}sb${NC}"
fi

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}安装完成!${NC}"
echo -e "${YELLOW}您可以使用 ${GREEN}sb${NC} ${YELLOW}命令启动服务器管理面板${NC}"
echo -e "${BLUE}=================================================${NC}" 
