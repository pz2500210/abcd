#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 在脚本开头添加
set -e  # 遇到错误立即退出
trap 'echo -e "${RED}脚本执行出错，请检查上面的错误信息${NC}"; exit 1' ERR

# 添加错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo -e "${RED}错误发生在第 $line_number 行，退出代码: $exit_code${NC}"
    echo -e "${YELLOW}请检查错误并重试，或联系管理员获取帮助${NC}"
}

trap 'handle_error $LINENO' ERR

# 显示欢迎信息
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}服务器初始化脚本${NC}"
echo -e "${BLUE}=================================================${NC}"

# 1. 修改SSH配置
modify_ssh_config() {
    echo -e "${YELLOW}[1/4] 修改SSH配置...${NC}"
    
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
}

# 2. 更新系统和安装工具
update_and_install() {
    echo -e "${YELLOW}[2/4] 更新系统和安装工具...${NC}"
    
    # 更新系统
    echo -e "${YELLOW}更新系统中，请稍候...${NC}"
    apt update && apt upgrade -y | tee /dev/null & 
    PID=$!
    while kill -0 $PID 2>/dev/null; do
        echo -n "."
        sleep 1
    done
    echo -e "\n${GREEN}系统更新完成${NC}"
    
    # 安装基础工具
    echo -e "${YELLOW}安装基础工具...${NC}"
    apt install -y curl wget vim unzip tar
    
    # 安装网络工具
    echo -e "${YELLOW}安装网络工具...${NC}"
    apt install -y net-tools dnsutils lsof
    
    # 安装证书和安全相关工具
    echo -e "${YELLOW}安装证书和安全相关工具...${NC}"
    apt install -y socat cron ca-certificates openssl
    
    # 安装开发和编译工具
    echo -e "${YELLOW}安装开发和编译工具...${NC}"
    apt install -y build-essential libssl-dev
    
    # 安装特定依赖
    echo -e "${YELLOW}安装特定依赖...${NC}"
    apt install -y jq qrencode # X-UI和Hysteria 2需要
    apt install -y python3-pip libsodium-dev # SSR需要
    
    # 再次更新
    apt update
    apt install -y curl socat cron
    
    # 确保cron服务启动并设置为开机自启
    systemctl enable cron
    systemctl start cron
    
    # 配置日志轮转
    configure_logrotate
    
    echo -e "${GREEN}系统更新和工具安装完成${NC}"
}

# 3. 设置时间同步
set_timezone() {
    echo -e "${YELLOW}[3/4] 设置时间同步...${NC}"
    
    # 获取当前系统时区
    CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
    echo -e "${GREEN}保持当前系统时区: ${CURRENT_TZ}${NC}"
    
    # 设置正确的系统时间（通过网络同步）
    apt install -y ntpdate
    ntpdate time.google.com || ntpdate ntp.aliyun.com
    
    # 安装和设置自动时间同步
    apt install -y systemd-timesyncd
    systemctl enable systemd-timesyncd
    systemctl start systemd-timesyncd
    
    echo -e "${GREEN}系统时间已同步: $(date)${NC}"
    echo -e "${YELLOW}已启用自动时间同步服务${NC}"
}

# 4. 配置BBR
configure_bbr() {
    echo -e "${YELLOW}[4/4] 配置BBR...${NC}"
    
    # 检查是否已启用BBR
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo -e "${GREEN}BBR已经启用${NC}"
    else
        # 添加BBR配置
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        
        # 验证BBR是否启用
        if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
            echo -e "${GREEN}BBR已成功启用${NC}"
        else
            echo -e "${RED}BBR启用失败，使用备用方法...${NC}"
            # 备用方法
            modprobe tcp_bbr
            echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p
            
            if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
                echo -e "${GREEN}BBR已成功启用（备用方法）${NC}"
            else
                echo -e "${RED}BBR启用失败，请手动检查${NC}"
            fi
        fi
    fi
    
    # 显示当前拥塞控制算法
    echo -e "${YELLOW}当前拥塞控制算法: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')${NC}"
}

# 添加新的函数
enhance_security() {
    echo -e "${YELLOW}[+] 增强系统安全性...${NC}"
    
    # 更新SSH配置以增强安全性
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config
    sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config
    
    # 配置自动安全更新
    apt install -y unattended-upgrades
    echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
    
    # 配置基本的系统安全参数
    echo "kernel.sysrq = 0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf
    sysctl -p
    
    echo -e "${GREEN}基本安全加固完成${NC}"
}

# 显示安装结果
show_results() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}服务器初始化完成!${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}系统信息:${NC}"
    echo -e "  系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  内核版本: $(uname -r)"
    echo -e "  IP地址: $(curl -s ifconfig.me)"
    echo -e "  时区: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    echo -e "  BBR状态: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo -e "  cron状态: $(systemctl is-active cron)"
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}===== 基础环境安装完成 =====${NC}"
    echo -e "${GREEN}===== 现在可以安装应用程序了 =====${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 添加常用命令提示
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  查看系统状态: ${GREEN}systemctl status${NC}"
    echo -e "  查看BBR状态: ${GREEN}sysctl net.ipv4.tcp_congestion_control${NC}"
    echo -e "${BLUE}=================================================${NC}"

    echo -e "${BLUE}=================================================${NC}"
    echo -e "${RED}★★★ 重要提示 ★★★${NC}"
    echo -e "${GREEN}服务器管理面板已安装!${NC}"
    echo -e "${YELLOW}输入命令 ${GREEN}xx${NC} ${YELLOW}随时启动管理面板${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

# 在脚本结束前添加
generate_config_summary() {
    CONFIG_FILE="/root/server_init_config.txt"
    echo "服务器初始化配置摘要 - $(date)" > $CONFIG_FILE
    echo "----------------------------------------" >> $CONFIG_FILE
    echo "系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')" >> $CONFIG_FILE
    echo "内核版本: $(uname -r)" >> $CONFIG_FILE
    echo "IP地址: $(curl -s ifconfig.me)" >> $CONFIG_FILE
    echo "时区: $(timedatectl | grep 'Time zone' | awk '{print $3}')" >> $CONFIG_FILE
    echo "BBR状态: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')" >> $CONFIG_FILE
    
    echo "----------------------------------------" >> $CONFIG_FILE
    echo "配置摘要已保存到: $CONFIG_FILE"
    
    # 设置权限
    chmod 600 $CONFIG_FILE
}

# 添加新的函数
configure_logrotate() {
    echo -e "${YELLOW}配置日志轮转...${NC}"
    apt install -y logrotate
    
    # 创建自定义日志轮转配置
    cat > /etc/logrotate.d/custom-logs << EOF
/var/log/auth.log
/var/log/syslog
/var/log/messages
{
    rotate 7
    daily
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
    
    echo -e "${GREEN}日志轮转配置完成${NC}"
}

# 主函数
main() {
    # 检查是否为root用户
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}此脚本必须以root用户身份运行${NC}"
        exit 1
    fi
    
    # 执行各个步骤
    modify_ssh_config
    update_and_install
    set_timezone
    configure_bbr
    enhance_security
    show_results
    generate_config_summary
}

# 执行主函数
main
