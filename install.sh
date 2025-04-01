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
echo -e "${GREEN}服务器管理系统修复脚本${NC}"
echo -e "${BLUE}=================================================${NC}"

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

# 创建临时目录
mkdir -p /tmp/server-fix
cd /tmp/server-fix

# 尝试多种下载方法
echo -e "${YELLOW}尝试下载文件 (方法1)...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o server_init.sh ${REPO_URL}/server_init.sh
curl -s -H "User-Agent: Mozilla/5.0" -o cleanup.sh ${REPO_URL}/cleanup.sh
curl -s -H "User-Agent: Mozilla/5.0" -o sb.sh ${REPO_URL}/sb.sh
curl -s -H "User-Agent: Mozilla/5.0" -o install_panel.sh ${REPO_URL}/install_panel.sh

# 检查文件是否下载成功
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${YELLOW}方法1失败，尝试方法2...${NC}"
    wget -q -O server_init.sh ${REPO_URL}/server_init.sh
    wget -q -O cleanup.sh ${REPO_URL}/cleanup.sh
    wget -q -O sb.sh ${REPO_URL}/sb.sh
    wget -q -O install_panel.sh ${REPO_URL}/install_panel.sh
fi

# 再次检查文件
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${YELLOW}方法2失败，尝试方法3...${NC}"
    # 尝试使用不同的URL格式
    ALT_REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main"
    curl -s -o server_init.sh ${ALT_REPO_URL}/server_init.sh
    curl -s -o cleanup.sh ${ALT_REPO_URL}/cleanup.sh
    curl -s -o sb.sh ${ALT_REPO_URL}/sb.sh
    curl -s -o install_panel.sh ${ALT_REPO_URL}/install_panel.sh
fi

# 最终检查
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s sb.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}所有下载方法都失败，请手动上传文件${NC}"
    exit 1
fi

# 检查文件内容
echo -e "${YELLOW}检查文件内容...${NC}"
head -n 5 server_init.sh
head -n 5 cleanup.sh
head -n 5 sb.sh
head -n 5 install_panel.sh

# 确认是否继续
read -p "文件内容看起来正确吗? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}操作已取消${NC}"
    exit 1
fi

# 复制文件到正确位置
echo -e "${YELLOW}复制文件到正确位置...${NC}"
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
rm -rf /tmp/server-fix

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}修复完成!${NC}"
echo -e "${YELLOW}您可以使用 ${GREEN}sb${NC} ${YELLOW}命令启动服务器管理面板${NC}"
echo -e "${YELLOW}或者运行 ${GREEN}bash /root/server_init.sh${NC} ${YELLOW}初始化服务器${NC}"
echo -e "${BLUE}=================================================${NC}" 