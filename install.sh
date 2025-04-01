#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 自动检测GitHub仓库URL
SCRIPT_URL=$(curl -s -I https://raw.githubusercontent.com/pz2500210/abcd/main/xx.sh | grep -i "location" | cut -d' ' -f2 | tr -d '\r')
if [[ -n "$SCRIPT_URL" && "$SCRIPT_URL" == *"refs/heads"* ]]; then
    REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main"
    echo -e "${YELLOW}使用URL: ${REPO_URL}${NC}"
else
    REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/main"
    echo -e "${YELLOW}使用URL: ${REPO_URL}${NC}"
fi

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}服务器管理系统安装程序${NC}"
echo -e "${BLUE}=================================================${NC}"

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

# 检查curl命令是否可用
if ! command -v curl &> /dev/null; then
    echo -e "${RED}curl命令不可用，正在安装...${NC}"
    apt-get update && apt-get install -y curl || yum install -y curl
fi

# 测试GitHub连接
echo -e "${YELLOW}测试GitHub连接...${NC}"
if ! curl -s -I https://raw.githubusercontent.com &> /dev/null; then
    echo -e "${RED}无法访问GitHub，请检查网络连接${NC}"
    exit 1
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

# 下载所有文件
echo -e "${YELLOW}正在下载必要文件，请稍候...${NC}"

# 创建临时目录
rm -rf /tmp/server-setup
mkdir -p /tmp/server-setup
cd /tmp/server-setup

# 下载文件
echo -e "${YELLOW}下载server_init.sh...${NC}"
curl -s -o server_init.sh ${REPO_URL}/server_init.sh
echo "server_init.sh 大小: $(du -b server_init.sh | cut -f1) 字节"

echo -e "${YELLOW}下载cleanup.sh...${NC}"
curl -s -o cleanup.sh ${REPO_URL}/cleanup.sh
echo "cleanup.sh 大小: $(du -b cleanup.sh | cut -f1) 字节"

echo -e "${YELLOW}下载xx.sh...${NC}"
curl -s -o xx.sh ${REPO_URL}/xx.sh
echo "xx.sh 大小: $(du -b xx.sh | cut -f1) 字节"

echo -e "${YELLOW}下载install_panel.sh...${NC}"
curl -s -o install_panel.sh ${REPO_URL}/install_panel.sh
echo "install_panel.sh 大小: $(du -b install_panel.sh | cut -f1) 字节"

# 检查文件是否下载成功
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s xx.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}文件下载失败，尝试备用URL...${NC}"
    
    # 尝试备用URL
    if [[ "$REPO_URL" == *"refs/heads"* ]]; then
        REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/main"
    else
        REPO_URL="https://raw.githubusercontent.com/pz2500210/abcd/refs/heads/main"
    fi
    
    echo -e "${YELLOW}使用备用URL: ${REPO_URL}${NC}"
    
    curl -s -o server_init.sh ${REPO_URL}/server_init.sh
    curl -s -o cleanup.sh ${REPO_URL}/cleanup.sh
    curl -s -o xx.sh ${REPO_URL}/xx.sh
    curl -s -o install_panel.sh ${REPO_URL}/install_panel.sh
    
    # 再次检查
    if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s xx.sh ] || [ ! -s install_panel.sh ]; then
        echo -e "${RED}文件下载失败，请检查网络连接或仓库地址${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}文件下载成功!${NC}"

# 复制文件到正确位置
echo -e "${YELLOW}复制文件到系统...${NC}"
cp -f server_init.sh /root/
cp -f cleanup.sh /root/
cp -f xx.sh /usr/local/bin/
cp -f install_panel.sh /root/

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
xx 