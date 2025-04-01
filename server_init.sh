#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示欢迎信息
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}服务器初始化脚本${NC}"
echo -e "${BLUE}=================================================${NC}"

# 1. 修改SSH配置
modify_ssh_config() {
    echo -e "${YELLOW}[1/5] 修改SSH配置...${NC}"
    
    # 备份原始SSH配置
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    echo -e "${YELLOW}修改SSH配置文件...${NC}"
    echo -e "${YELLOW}#     按 I   进入编辑 ${NC}"
    echo -e "${YELLOW}#     port 22                #去掉#号，打开22端口${NC}"
    echo -e "${YELLOW}#     PermitRootLogin yes     #添加到 POSSWORD下方${NC}"
    echo -e "${YELLOW}#     PasswordAuthentication yes # NO修改为YES${NC}"
    echo -e "${YELLOW}#     修改后，ESC退出编辑  :wq 保存退出${NC}"
    
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
    echo -e "${YELLOW}[2/5] 更新系统和安装工具...${NC}"
    
    # 更新系统
    echo -e "${YELLOW}更新系统...${NC}"
    apt update && apt upgrade -y
    
    # 安装基础工具
    echo -e "${YELLOW}安装基础工具...${NC}"
    apt install -y curl wget vim unzip tar
    
    # 安装网络工具
    echo -e "${YELLOW}安装网络工具...${NC}"
    apt install -y net-tools iptables-persistent dnsutils lsof
    
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
    
    echo -e "${GREEN}系统更新和工具安装完成${NC}"
}

# 3. 设置时区
set_timezone() {
    echo -e "${YELLOW}[3/5] 设置时区...${NC}"
    
    # 获取当前系统时区
    CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
    
    # 显示常用时区选项
    echo -e "${YELLOW}请选择时区 (当前时区: ${CURRENT_TZ}):${NC}"
    echo -e "  1) 亚洲/上海 (中国)"
    echo -e "  2) 亚洲/新加坡"
    echo -e "  3) 亚洲/东京 (日本)"
    echo -e "  4) 美国/洛杉矶 (美国西部)"
    echo -e "  5) 美国/纽约 (美国东部)"
    echo -e "  6) 欧洲/伦敦 (英国)"
    echo -e "  7) 欧洲/巴黎 (法国)"
    echo -e "  8) 自定义时区"
    echo -e "  9) 保持当前时区 (${CURRENT_TZ})"
    
    read -p "请输入选项 [1-9] (默认: 9): " TIMEZONE_OPTION
    TIMEZONE_OPTION=${TIMEZONE_OPTION:-9}
    
    case $TIMEZONE_OPTION in
        1) TZ="Asia/Shanghai" ;;
        2) TZ="Asia/Singapore" ;;
        3) TZ="Asia/Tokyo" ;;
        4) TZ="America/Los_Angeles" ;;
        5) TZ="America/New_York" ;;
        6) TZ="Europe/London" ;;
        7) TZ="Europe/Paris" ;;
        8) 
            # 列出所有可用时区
            echo -e "${YELLOW}可用的时区列表:${NC}"
            timedatectl list-timezones | less
            echo -e "${YELLOW}请输入您想要设置的时区 (例如: Asia/Shanghai):${NC}"
            read -p "时区: " TZ
            ;;
        9) 
            echo -e "${GREEN}保持当前时区: ${CURRENT_TZ}${NC}"
            TZ=$CURRENT_TZ
            ;;
        *) 
            echo -e "${RED}无效选项，使用当前时区 ${CURRENT_TZ}${NC}"
            TZ=$CURRENT_TZ
            ;;
    esac
    
    # 如果选择了新的时区，则设置
    if [ "$TZ" != "$CURRENT_TZ" ]; then
        timedatectl set-timezone $TZ
        echo -e "${GREEN}时区已更改为: $TZ${NC}"
    fi
    
    # 设置正确的系统时间
    apt install -y ntpdate
    ntpdate time.google.com || ntpdate ntp.aliyun.com
    
    echo -e "${GREEN}时区设置完成: $(timedatectl | grep "Time zone")${NC}"
    echo -e "${YELLOW}当前系统时间: $(date)${NC}"
    echo -e "${YELLOW}注意: 无论选择哪个时区，只要系统时间准确，都不会影响VPN使用${NC}"
}

# 4. 配置BBR
configure_bbr() {
    echo -e "${YELLOW}[4/5] 配置BBR...${NC}"
    
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

# 5. 安装和配置acme.sh
install_acme() {
    echo -e "${YELLOW}[5/5] 安装和配置acme.sh...${NC}"
    
    # 安装acme.sh
    curl https://get.acme.sh | sh
    
    # 注册账户
    echo -e "${YELLOW}请输入您的邮箱地址(用于注册acme.sh账户，直接回车使用默认邮箱):${NC}"
    read -p "邮箱: " EMAIL
    if [ -z "$EMAIL" ]; then
        EMAIL="xxxx@xxxx.com"
        echo -e "${YELLOW}使用默认邮箱: $EMAIL${NC}"
    fi
    ~/.acme.sh/acme.sh --register-account -m $EMAIL
    
    # 询问是否申请证书
    echo -e "${YELLOW}是否申请SSL证书? (Y/N)${NC}"
    read -p "选择 [Y/N]: " APPLY_CERT
    
    if [[ "$APPLY_CERT" =~ ^[Yy]$ ]]; then
        # 获取域名
        echo -e "${YELLOW}请输入您的域名:${NC}"
        read -p "域名: " DOMAIN
        
        if [ -z "$DOMAIN" ]; then
            echo -e "${RED}域名不能为空，跳过证书申请${NC}"
        else
            # 申请证书
            ~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone
            
            # 安装证书
            ~/.acme.sh/acme.sh --installcert -d $DOMAIN --key-file /root/private.key --fullchain-file /root/cert.crt
            
            echo -e "${GREEN}证书已安装到: /root/private.key 和 /root/cert.crt${NC}"
        fi
    else
        echo -e "${YELLOW}您选择了不申请SSL证书${NC}"
    fi
    
    # 安装wget和curl
    apt-get install wget curl -y
    
    echo -e "${GREEN}acme.sh安装和配置完成${NC}"
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
    install_acme
    show_results
}

# 执行主函数
main
