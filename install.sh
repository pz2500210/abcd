#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 启用调试模式
set -x

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

# 检查并终止可能正在运行的xx进程
if pgrep -f "xx.sh" > /dev/null; then
    echo -e "${YELLOW}检测到xx.sh正在运行，尝试终止...${NC}"
    pkill -f "xx.sh"
    sleep 2
fi

# 检查并删除可能存在的xx命令
if [ -f "/usr/local/bin/xx" ]; then
    echo -e "${YELLOW}检测到xx命令已存在，正在删除...${NC}"
    rm -f /usr/local/bin/xx
fi

# 检查并删除可能存在的xx.sh文件
if [ -f "/usr/local/bin/xx.sh" ]; then
    echo -e "${YELLOW}检测到xx.sh文件已存在，正在删除...${NC}"
    rm -f /usr/local/bin/xx.sh
fi

# 修改SSH配置
echo -e "${YELLOW}修改SSH配置...${NC}"
# 备份原始SSH配置
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 自动修改SSH配置
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 重启SSH服务
systemctl restart sshd
echo -e "${GREEN}SSH配置已修改完成${NC}"

# 静默下载所有文件
echo -e "${YELLOW}正在下载必要文件，请稍候...${NC}"

# 创建临时目录
rm -rf /tmp/server-setup
mkdir -p /tmp/server-setup
cd /tmp/server-setup

# 下载文件
echo -e "${YELLOW}下载server_init.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o server_init.sh ${REPO_URL}/server_init.sh
echo "server_init.sh 下载状态: $?"

echo -e "${YELLOW}下载cleanup.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o cleanup.sh ${REPO_URL}/cleanup.sh
echo "cleanup.sh 下载状态: $?"

echo -e "${YELLOW}下载xx.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o xx.sh ${REPO_URL}/xx.sh
echo "xx.sh 下载状态: $?"

echo -e "${YELLOW}下载install_panel.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o install_panel.sh ${REPO_URL}/install_panel.sh
echo "install_panel.sh 下载状态: $?"

# 检查文件是否下载成功
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s xx.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}文件下载失败，尝试备用下载方法...${NC}"
    
    # 备用下载方法
    echo -e "${YELLOW}使用备用URL下载...${NC}"
    ALT_REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main"
    
    curl -s -o server_init.sh ${ALT_REPO_URL}/server_init.sh
    curl -s -o cleanup.sh ${ALT_REPO_URL}/cleanup.sh
    curl -s -o xx.sh ${ALT_REPO_URL}/xx.sh
    curl -s -o install_panel.sh ${ALT_REPO_URL}/install_panel.sh
fi

# 再次检查文件是否下载成功
if [ ! -s server_init.sh ]; then
    echo -e "${RED}server_init.sh 下载失败${NC}"
    exit 1
fi

if [ ! -s cleanup.sh ]; then
    echo -e "${RED}cleanup.sh 下载失败${NC}"
    exit 1
fi

if [ ! -s xx.sh ]; then
    echo -e "${RED}xx.sh 下载失败${NC}"
    exit 1
fi

if [ ! -s install_panel.sh ]; then
    echo -e "${RED}install_panel.sh 下载失败${NC}"
    exit 1
fi

echo -e "${GREEN}文件下载成功!${NC}"

# 检查文件内容
echo -e "${YELLOW}检查xx.sh文件内容...${NC}"
head -n 10 xx.sh
echo "..."
tail -n 10 xx.sh

# 复制文件到正确位置
echo -e "${YELLOW}复制文件到系统...${NC}"
cp server_init.sh /root/
cp cleanup.sh /root/
cp xx.sh /usr/local/bin/
cp install_panel.sh /root/

# 设置执行权限
chmod +x /root/server_init.sh
chmod +x /root/cleanup.sh
chmod +x /usr/local/bin/xx.sh
chmod +x /root/install_panel.sh

# 创建xx命令链接
echo -e "${YELLOW}创建xx命令...${NC}"
ln -sf /usr/local/bin/xx.sh /usr/local/bin/xx
chmod +x /usr/local/bin/xx

# 检查xx命令是否可用
echo -e "${YELLOW}检查xx命令...${NC}"
which xx
ls -la $(which xx)
file $(which xx)

# 清理临时文件
cd ~
rm -rf /tmp/server-setup

echo -e "${GREEN}安装完成！正在启动服务器管理面板...${NC}"

# 直接启动XX面板
echo -e "${YELLOW}启动xx命令...${NC}"
xx || echo -e "${RED}xx命令执行失败，错误代码: $?${NC}"

# 禁用调试模式
set +x 