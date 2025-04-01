#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示欢迎信息
echo -e "${BLUE}=================================================${NC}"
echo -e "${RED}服务器初始化脚本清理工具${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}警告: 此脚本将删除由server_init.sh或xx.sh安装的所有内容${NC}"
echo -e "${YELLOW}      请确保您已备份重要数据${NC}"
echo -e "${BLUE}=================================================${NC}"

# 确认是否继续
read -p "是否继续清理? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}清理已取消${NC}"
    exit 1
fi

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

echo -e "${YELLOW}请选择要清理的组件:${NC}"
echo -e "  1) SSH配置"
echo -e "  2) 安装的软件包"
echo -e "  3) 时区设置"
echo -e "  4) BBR配置"
echo -e "  5) acme.sh和证书"
echo -e "  6) 全部清理"
read -p "选择 [1-6] (默认: 6): " CLEANUP_OPTION
CLEANUP_OPTION=${CLEANUP_OPTION:-6}

case $CLEANUP_OPTION in
    1) cleanup_ssh ;;
    2) cleanup_packages ;;
    3) cleanup_timezone ;;
    4) cleanup_bbr ;;
    5) cleanup_acme ;;
    6) 
        cleanup_ssh
        cleanup_packages
        cleanup_timezone
        cleanup_bbr
        cleanup_acme
        ;;
    *)
        echo -e "${RED}无效选项，退出${NC}"
        exit 1
        ;;
esac

# 在清理前添加
backup_configs() {
    echo -e "${YELLOW}备份重要配置...${NC}"
    BACKUP_DIR="/root/config_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    # 备份SSH配置
    cp /etc/ssh/sshd_config $BACKUP_DIR/ 2>/dev/null || true
    
    # 备份证书
    if [ -f /root/private.key ]; then
        cp /root/private.key $BACKUP_DIR/ 2>/dev/null || true
        cp /root/cert.crt $BACKUP_DIR/ 2>/dev/null || true
    fi
    
    # 备份系统配置
    cp /etc/sysctl.conf $BACKUP_DIR/ 2>/dev/null || true
    
    echo -e "${GREEN}配置已备份到: $BACKUP_DIR${NC}"
}

# 在主函数中调用
backup_configs

# 1. 恢复SSH配置
echo -e "${YELLOW}[1/6] 恢复SSH配置...${NC}"
if [ -f /etc/ssh/sshd_config.bak ]; then
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${GREEN}SSH配置已恢复${NC}"
else
    echo -e "${RED}未找到SSH配置备份，尝试手动修复...${NC}"
    # 尝试恢复默认设置
    sed -i 's/^Port 22/#Port 22/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin yes/#PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${YELLOW}SSH配置已尝试恢复到默认状态，请手动检查${NC}"
fi

# 2. 删除安装的软件包
echo -e "${YELLOW}[2/6] 删除安装的软件包...${NC}"
apt-get remove -y curl wget vim unzip tar net-tools iptables-persistent dnsutils lsof socat cron ca-certificates openssl build-essential libssl-dev jq qrencode python3-pip libsodium-dev ntpdate 2>/dev/null
echo -e "${GREEN}软件包已删除${NC}"

# 3. 恢复时区设置
echo -e "${YELLOW}[3/6] 恢复时区设置...${NC}"
timedatectl set-timezone UTC
echo -e "${GREEN}时区已重置为UTC${NC}"

# 4. 删除BBR配置
echo -e "${YELLOW}[4/6] 删除BBR配置...${NC}"
sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
sed -i '/tcp_bbr/d' /etc/modules-load.d/modules.conf 2>/dev/null
sysctl -p
echo -e "${GREEN}BBR配置已删除${NC}"

# 5. 删除acme.sh和证书
echo -e "${YELLOW}[5/6] 删除acme.sh和证书...${NC}"
if [ -d ~/.acme.sh ]; then
    ~/.acme.sh/acme.sh --uninstall
    rm -rf ~/.acme.sh
    echo -e "${GREEN}acme.sh已卸载${NC}"
fi

# 删除证书文件
rm -f /root/private.key /root/cert.crt
echo -e "${GREEN}证书文件已删除${NC}"

# 6. 清理其他文件和目录
echo -e "${YELLOW}[6/6] 清理其他文件和目录...${NC}"
# 删除脚本文件
rm -f /root/server_init.sh /root/xx.sh 2>/dev/null

# 清理apt缓存
apt-get clean
apt-get autoremove -y

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}清理完成!${NC}"
echo -e "${YELLOW}注意: 某些更改可能需要重启服务器才能完全生效${NC}"
echo -e "${YELLOW}建议: 完成测试后重启服务器${NC}"
echo -e "${BLUE}=================================================${NC}"

# 询问是否立即重启
read -p "是否立即重启服务器? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}服务器将在5秒后重启...${NC}"
    sleep 5
    reboot
fi 