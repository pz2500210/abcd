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

# 检查是否是重新安装
REINSTALL=false
if [ -f "/usr/local/bin/xx.sh" ] || [ -f "/usr/local/bin/xx" ]; then
    echo -e "${YELLOW}检测到系统中已存在安装，是否重新安装？(y/n)${NC}"
    read -p "选择 [y/n]: " REINSTALL_CONFIRM
    
    if [[ $REINSTALL_CONFIRM =~ ^[Yy]$ ]]; then
        REINSTALL=true
        echo -e "${YELLOW}将进行重新安装...${NC}"
        
        # 备份日志
        if [ -d "/root/.sb_logs" ]; then
            echo -e "${YELLOW}备份现有日志...${NC}"
            cp -r /root/.sb_logs /root/.sb_logs.bak.$(date +%Y%m%d%H%M%S)
        fi
        
        # 终止运行中的进程
        if pgrep -f "xx.sh" > /dev/null; then
            echo -e "${YELLOW}终止运行中的xx.sh进程...${NC}"
            pkill -f "xx.sh"
            sleep 2
        fi
        
        # 删除现有文件
        echo -e "${YELLOW}删除现有文件...${NC}"
        rm -f /usr/local/bin/xx
        rm -f /usr/local/bin/xx.sh
        rm -f /root/server_init.sh
        rm -f /root/cleanup.sh
        rm -f /root/install_panel.sh
    else
        echo -e "${GREEN}已取消重新安装，退出脚本${NC}"
        exit 0
    fi
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
if [ $? -ne 0 ] || [ ! -s server_init.sh ]; then
    echo -e "${RED}server_init.sh 下载失败，尝试备用URL...${NC}"
    curl -s -o server_init.sh https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main/server_init.sh
fi

echo -e "${YELLOW}下载cleanup.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o cleanup.sh ${REPO_URL}/cleanup.sh
if [ $? -ne 0 ] || [ ! -s cleanup.sh ]; then
    echo -e "${RED}cleanup.sh 下载失败，尝试备用URL...${NC}"
    curl -s -o cleanup.sh https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main/cleanup.sh
fi

echo -e "${YELLOW}下载xx.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o xx.sh ${REPO_URL}/xx.sh
if [ $? -ne 0 ] || [ ! -s xx.sh ]; then
    echo -e "${RED}xx.sh 下载失败，尝试备用URL...${NC}"
    curl -s -o xx.sh https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main/xx.sh
fi

echo -e "${YELLOW}下载install_panel.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o install_panel.sh ${REPO_URL}/install_panel.sh
if [ $? -ne 0 ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}install_panel.sh 下载失败，尝试备用URL...${NC}"
    curl -s -o install_panel.sh https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main/install_panel.sh
fi

# 检查文件是否下载成功
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

# 创建日志目录
mkdir -p /root/.sb_logs
touch /root/.sb_logs/main_install.log

# 清理临时文件
cd ~
rm -rf /tmp/server-setup

echo -e "${GREEN}安装完成！正在启动服务器管理面板...${NC}"

# 直接启动XX面板
echo -e "${YELLOW}启动xx命令...${NC}"
xx || {
    echo -e "${RED}xx命令执行失败，错误代码: $?${NC}"
    echo -e "${YELLOW}尝试直接执行xx.sh...${NC}"
    bash /usr/local/bin/xx.sh || {
        echo -e "${RED}xx.sh执行也失败，可能是文件损坏${NC}"
        echo -e "${YELLOW}尝试重新下载xx.sh...${NC}"
        curl -s -H "User-Agent: Mozilla/5.0" -o /usr/local/bin/xx.sh ${REPO_URL}/xx.sh
        chmod +x /usr/local/bin/xx.sh
        bash /usr/local/bin/xx.sh
    }
}

# 禁用调试模式
set +x 