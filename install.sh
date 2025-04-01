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
mkdir -p /tmp/server-setup
cd /tmp/server-setup

# 下载文件
echo -e "${YELLOW}下载server_init.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o server_init.sh ${REPO_URL}/server_init.sh

echo -e "${YELLOW}下载cleanup.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o cleanup.sh ${REPO_URL}/cleanup.sh

echo -e "${YELLOW}下载xx.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o xx.sh ${REPO_URL}/xx.sh

echo -e "${YELLOW}下载install_panel.sh...${NC}"
curl -s -H "User-Agent: Mozilla/5.0" -o install_panel.sh ${REPO_URL}/install_panel.sh

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
if [ ! -s server_init.sh ] || [ ! -s cleanup.sh ] || [ ! -s xx.sh ] || [ ! -s install_panel.sh ]; then
    echo -e "${RED}文件下载失败，请检查网络连接或仓库地址${NC}"
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

# 清理临时文件
cd ~
rm -rf /tmp/server-setup

echo -e "${GREEN}安装完成！正在启动服务器管理面板...${NC}"

# 直接启动XX面板
xx

# 使用HTTP验证申请证书
issue_certificate_http() {
    local domain=$1
    
    echo -e "${YELLOW}使用HTTP验证申请证书...${NC}"
    
    # 检查80端口是否被占用
    if netstat -tuln | grep -q ':80 '; then
        echo -e "${YELLOW}检测到80端口被占用，尝试停止占用服务...${NC}"
        # 尝试停止可能占用80端口的服务
        systemctl stop nginx 2>/dev/null || true
        systemctl stop apache2 2>/dev/null || true
        systemctl stop httpd 2>/dev/null || true
        
        # 再次检查端口
        if netstat -tuln | grep -q ':80 '; then
            echo -e "${RED}无法释放80端口，请手动停止占用80端口的服务后重试${NC}"
            return 1
        fi
    fi
    
    # 确保防火墙允许80端口
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp >/dev/null 2>&1 || true
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=80/tcp >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
    elif command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT >/dev/null 2>&1 || true
    fi
    
    # 使用standalone模式申请证书
    /root/.acme.sh/acme.sh --issue -d "$domain" --standalone
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$domain"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
} 