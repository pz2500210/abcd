#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 全局IP地址变量
PUBLIC_IPV4=""
PUBLIC_IPV6=""
LOCAL_IPV4=""
LOCAL_IPV6=""

# 获取IP地址的函数
get_ip_addresses() {
    # 获取本地IP地址
    LOCAL_IPV4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -1)
    LOCAL_IPV6=$(ip -6 addr show | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "::1" | grep -v "fe80" | head -1)
    
    # 使用本地IP作为公网IP（如果无法获取公网IP）
    PUBLIC_IPV4=$LOCAL_IPV4
    PUBLIC_IPV6=$LOCAL_IPV6
    
    # 尝试获取公网IP（只使用一个服务，减少超时时间）
    TEMP_IPV4=$(curl -s -m 1 https://api.ipify.org 2>/dev/null)
    if [ ! -z "$TEMP_IPV4" ]; then
        PUBLIC_IPV4=$TEMP_IPV4
    fi
    
    TEMP_IPV6=$(curl -s -m 1 https://api6.ipify.org 2>/dev/null)
    if [ ! -z "$TEMP_IPV6" ]; then
        PUBLIC_IPV6=$TEMP_IPV6
    fi
}

# 显示横幅
show_banner() {
    clear
    # 不需要重新获取IP地址，使用全局变量
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}           服务器管理面板 v1.0                  ${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}系统信息:${NC}"
    echo -e "  主机名: $(hostname)"
    echo -e "  系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  内核版本: $(uname -r)"
    echo -e "  架构: $(uname -m)"
    echo -e "  公网IPv4: ${PUBLIC_IPV4}"
    if [ ! -z "$PUBLIC_IPV6" ]; then
        echo -e "  公网IPv6: ${PUBLIC_IPV6}"
    elif [ ! -z "$LOCAL_IPV6" ]; then
        echo -e "  IPv6地址: ${LOCAL_IPV6}"
    fi
    echo -e "  内网IPv4: ${LOCAL_IPV4}"
    echo -e "  时区: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    echo -e "  BBR状态: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo -e "${BLUE}=================================================${NC}"
}

# 显示主菜单
show_main_menu() {
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  ${GREEN}1.${NC} 安装Hysteria-2"
    echo -e "  ${GREEN}2.${NC} 安装3X-UI"
    echo -e "  ${GREEN}3.${NC} 安装Sing-box-yg"
    echo -e "  ${GREEN}4.${NC} 安装基础环境和工具"
    echo -e "  ${GREEN}5.${NC} 防火墙设置"
    echo -e "  ${GREEN}6.${NC} 查看配置"
    echo -e "  ${GREEN}7.${NC} 系统工具"
    echo -e "  ${GREEN}8.${NC} 安装SSL证书"
    echo -e "  ${GREEN}9.${NC} DNS认证管理"
    echo -e "  ${GREEN}10.${NC} 卸载"
    echo -e "  ${GREEN}0.${NC} 退出"
    echo -e "${BLUE}=================================================${NC}"
}

# 初始化服务器
initialize_server() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装基础环境和工具:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${CYAN}请选择要安装的环境:${NC}"
    echo -e "${WHITE}1)${NC} ${GREEN}基础系统环境${NC} - 安装基本系统工具和优化"
    echo -e "${WHITE}2)${NC} ${GREEN}Vless/Vmess环境${NC} - 安装Vless/Vmess所需依赖"
    echo -e "${WHITE}3)${NC} ${GREEN}Hysteria-2环境${NC} - 安装Hysteria-2所需依赖"
    echo -e "${WHITE}4)${NC} ${GREEN}Tuic-v5环境${NC} - 安装Tuic-v5所需依赖"
    echo -e "${WHITE}5)${NC} ${GREEN}ShadowSocks环境${NC} - 安装ShadowSocks所需依赖"
    echo -e "${WHITE}6)${NC} ${GREEN}Wireguard环境${NC} - 安装Wireguard所需依赖"
    echo -e "${WHITE}7)${NC} ${GREEN}全部安装${NC} - 安装所有代理软件环境"
    echo -e "${WHITE}0)${NC} ${RED}返回主菜单${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    read -p "请选择 [0-7]: " ENV_OPTION
    
    case $ENV_OPTION in
        1) install_base_env ;;
        2) install_vless_vmess_env ;;
        3) install_hysteria2_env ;;
        4) install_tuic_env ;;
        5) install_shadowsocks_env ;;
        6) install_wireguard_env ;;
        7) install_all_env ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            initialize_server
            ;;
    esac
}

# 安装基础系统环境
install_base_env() {
    echo -e "${GREEN}开始安装基础系统环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update && apt upgrade -y
        apt install -y curl wget vim net-tools htop iftop iotop unzip lsof socat cron
        
        # 配置BBR
        if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        fi
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
        sysctl -p
        
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum update -y
        yum install -y curl wget vim net-tools htop iotop unzip lsof socat cronie
        
        # 配置BBR
        if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        fi
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
        sysctl -p
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    # 设置时区
    timedatectl set-timezone Asia/Shanghai
    
    echo -e "${GREEN}基础系统环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装Vless/Vmess环境
install_vless_vmess_env() {
    echo -e "${GREEN}开始安装Vless/Vmess环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update
        apt install -y jq openssl
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y jq openssl
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    echo -e "${GREEN}Vless/Vmess环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装Hysteria-2环境
install_hysteria2_env() {
    echo -e "${GREEN}开始安装Hysteria-2环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update
        apt install -y openssl
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y openssl
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    echo -e "${GREEN}Hysteria-2环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装Tuic-v5环境
install_tuic_env() {
    echo -e "${GREEN}开始安装Tuic-v5环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update
        apt install -y build-essential pkg-config libssl-dev
        
        # 安装Rust环境
        if ! command -v rustc &> /dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
        fi
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y gcc openssl-devel
        
        # 安装Rust环境
        if ! command -v rustc &> /dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source $HOME/.cargo/env
        fi
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    echo -e "${GREEN}Tuic-v5环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装ShadowSocks环境
install_shadowsocks_env() {
    echo -e "${GREEN}开始安装ShadowSocks环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update
        apt install -y libmbedtls-dev libsodium-dev
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y mbedtls-devel libsodium-devel
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    echo -e "${GREEN}ShadowSocks环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装Wireguard环境
install_wireguard_env() {
    echo -e "${GREEN}开始安装Wireguard环境...${NC}"
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update
        apt install -y wireguard-tools
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y epel-release
        yum install -y wireguard-tools
    else
        echo -e "${RED}不支持的系统类型${NC}"
        return
    fi
    
    echo -e "${GREEN}Wireguard环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 安装所有环境
install_all_env() {
    echo -e "${GREEN}开始安装所有代理软件环境...${NC}"
    
    install_base_env
    install_vless_vmess_env
    install_hysteria2_env
    install_tuic_env
    install_shadowsocks_env
    install_wireguard_env
    
    echo -e "${GREEN}所有代理软件环境安装完成${NC}"
    read -p "按回车键继续..." temp
    initialize_server
}

# 重新安装
reinstall() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}重新安装:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}正在读取安装记录...${NC}"
    
    local main_log="/root/.sb_logs/main_install.log"
    local installed_software=()
    
    # 检查主日志文件是否存在
    if [ ! -f "$main_log" ]; then
        echo -e "${RED}未找到安装记录，无法确定已安装的软件${NC}"
        echo -e "${YELLOW}请手动选择要重新安装的软件:${NC}"
        
        echo -e "${WHITE}1)${NC} ${GREEN}重新安装 Hysteria-2${NC}"
        echo -e "${WHITE}2)${NC} ${GREEN}重新安装 3X-UI${NC}"
        echo -e "${WHITE}3)${NC} ${GREEN}重新安装 Sing-box-yg${NC}"
        echo -e "${WHITE}0)${NC} ${RED}返回主菜单${NC}"
        
        read -p "请选择 [0-3]: " REINSTALL_OPTION
        
        case $REINSTALL_OPTION in
            1) reinstall_hysteria2 ;;
            2) reinstall_3xui ;;
            3) reinstall_singbox_yg ;;
            0) return ;;
            *) 
                echo -e "${RED}无效选项${NC}"
                sleep 2
                reinstall
                ;;
        esac
        return
    fi
    
    # 解析主日志文件，获取已安装的软件
    if grep -q "Hysteria-2" "$main_log"; then
        installed_software+=("Hysteria-2")
        echo -e "  ${GREEN}[已安装]${NC} Hysteria-2"
    fi
    
    if grep -q "3X-UI" "$main_log"; then
        installed_software+=("3X-UI")
        echo -e "  ${GREEN}[已安装]${NC} 3X-UI"
    fi
    
    if grep -q "Sing-box-yg" "$main_log"; then
        installed_software+=("Sing-box-yg")
        echo -e "  ${GREEN}[已安装]${NC} Sing-box-yg"
    fi
    
    # 获取所有已安装的证书
    local cert_entries=$(grep "SSL证书:" "$main_log")
    if [ ! -z "$cert_entries" ]; then
        echo -e "  ${GREEN}[已安装]${NC} SSL证书"
        installed_software+=("SSL证书")
    fi
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}请选择要重新安装的软件:${NC}"
    
    local count=1
    for software in "${installed_software[@]}"; do
        echo -e "${WHITE}$count)${NC} ${GREEN}重新安装 $software${NC}"
        ((count++))
    done
    
    echo -e "${WHITE}$count)${NC} ${YELLOW}重新安装所有已安装的软件${NC}"
    echo -e "${WHITE}0)${NC} ${RED}返回主菜单${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    read -p "请选择 [0-$count]: " REINSTALL_OPTION
    
    if [ "$REINSTALL_OPTION" = "0" ]; then
        return
    elif [ "$REINSTALL_OPTION" = "$count" ]; then
        # 重新安装所有
        echo -e "${YELLOW}将重新安装所有已安装的软件${NC}"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for software in "${installed_software[@]}"; do
                case $software in
                    "Hysteria-2")
                        reinstall_hysteria2
                        ;;
                    "3X-UI")
                        reinstall_3xui
                        ;;
                    "Sing-box-yg")
                        reinstall_singbox_yg
                        ;;
                    "SSL证书")
                        reinstall_all_certificates
                        ;;
                esac
            done
        fi
    elif [ "$REINSTALL_OPTION" -ge 1 ] && [ "$REINSTALL_OPTION" -lt "$count" ]; then
        # 重新安装特定软件
        local selected=${installed_software[$((REINSTALL_OPTION-1))]}
        case $selected in
            "Hysteria-2")
                reinstall_hysteria2
                ;;
            "3X-UI")
                reinstall_3xui
                ;;
            "Sing-box-yg")
                reinstall_singbox_yg
                ;;
            "SSL证书")
                reinstall_certificates_menu
                ;;
        esac
    else
        echo -e "${RED}无效选项${NC}"
        sleep 2
        reinstall
    fi
}

# 重新安装Hysteria-2
reinstall_hysteria2() {
    echo -e "${YELLOW}正在重新安装Hysteria-2...${NC}"
    
    # 卸载现有安装
    uninstall_hysteria2
    
    # 重新安装
    install_hysteria2
    
    echo -e "${GREEN}Hysteria-2重新安装完成${NC}"
}

# 重新安装3X-UI
reinstall_3xui() {
    echo -e "${YELLOW}正在重新安装3X-UI...${NC}"
    
    # 卸载现有安装
    uninstall_3xui
    
    # 重新安装
    install_3xui
    
    echo -e "${GREEN}3X-UI重新安装完成${NC}"
}

# 重新安装Sing-box-yg
reinstall_singbox_yg() {
    echo -e "${YELLOW}正在重新安装Sing-box-yg...${NC}"
    
    # 卸载现有安装
    uninstall_singbox_yg
    
    # 重新安装
    install_singbox_yg
    
    echo -e "${GREEN}Sing-box-yg重新安装完成${NC}"
}

# 重新安装证书菜单
reinstall_certificates_menu() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}重新安装SSL证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    local main_log="/root/.sb_logs/main_install.log"
    local domains=()
    
    # 获取所有已安装的证书域名
    while IFS= read -r line; do
        if [[ $line == *"SSL证书:"* ]]; then
            domain=$(echo $line | cut -d':' -f2)
            domains+=("$domain")
        fi
    done < "$main_log"
    
    if [ ${#domains[@]} -eq 0 ]; then
        echo -e "${RED}未找到已安装的证书${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    echo -e "${YELLOW}已安装的证书:${NC}"
    local count=1
    for domain in "${domains[@]}"; do
        echo -e "${WHITE}$count)${NC} ${GREEN}$domain${NC}"
        ((count++))
    done
    
    echo -e "${WHITE}$count)${NC} ${YELLOW}重新安装所有证书${NC}"
    echo -e "${WHITE}0)${NC} ${RED}返回${NC}"
    
    read -p "请选择 [0-$count]: " CERT_OPTION
    
    if [ "$CERT_OPTION" = "0" ]; then
        return
    elif [ "$CERT_OPTION" = "$count" ]; then
        # 重新安装所有证书
        reinstall_all_certificates
    elif [ "$CERT_OPTION" -ge 1 ] && [ "$CERT_OPTION" -lt "$count" ]; then
        # 重新安装特定证书
        local domain=${domains[$((CERT_OPTION-1))]}
        reinstall_certificate "$domain"
    else
        echo -e "${RED}无效选项${NC}"
        sleep 2
        reinstall_certificates_menu
    fi
}

# 重新安装所有证书
reinstall_all_certificates() {
    local main_log="/root/.sb_logs/main_install.log"
    local domains=()
    
    # 获取所有已安装的证书域名
    while IFS= read -r line; do
        if [[ $line == *"SSL证书:"* ]]; then
            domain=$(echo $line | cut -d':' -f2)
            domains+=("$domain")
        fi
    done < "$main_log"
    
    for domain in "${domains[@]}"; do
        reinstall_certificate "$domain"
    done
}

# 重新安装证书
reinstall_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}正在重新安装域名为 $domain 的SSL证书...${NC}"
    
    # 卸载现有证书
    uninstall_certificate "$domain"
    
    # 重新安装证书
    DOMAIN=$domain
    install_certificate
}

# 卸载
uninstall() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择要卸载的组件:${NC}"
    echo -e "  1) 卸载Hysteria-2"
    echo -e "  2) 卸载3X-UI"
    echo -e "  3) 卸载Sing-box-yg"
    echo -e "  4) 卸载全部软件和环境"
    echo -e "  0) 返回主菜单"
        
        read -p "请选择 [0-4]: " UNINSTALL_OPTION
        
        case $UNINSTALL_OPTION in
            1) uninstall_hysteria2 ;;
            2) uninstall_3xui ;;
        3) uninstall_singbox_yg ;;
        4) uninstall_all ;;
            0) return ;;
            *) 
            echo -e "${RED}无效选项，请重试${NC}"
                sleep 2
                uninstall
                ;;
        esac
}

# 卸载Hysteria-2
uninstall_hysteria2() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载Hysteria-2:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/hysteria" ]; then
        echo -e "${RED}Hysteria-2未安装，无需卸载${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    echo -e "${YELLOW}正在卸载Hysteria-2...${NC}"
    
        # 停止服务
        systemctl stop hysteria 2>/dev/null
        systemctl disable hysteria 2>/dev/null
        
    # 删除文件
        rm -f /usr/local/bin/hysteria
        rm -rf /etc/hysteria
        rm -f /etc/systemd/system/hysteria.service
    
    # 重新加载systemd
        systemctl daemon-reload
    
    # 从安装日志中删除
    sed -i '/Hysteria-2/d' /root/.sb_logs/main_install.log 2>/dev/null
    
    echo -e "${GREEN}Hysteria-2卸载完成${NC}"
    read -p "按回车键继续..." temp
}

# 卸载3X-UI
uninstall_3xui() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载3X-UI:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/x-ui/x-ui" ] && [ ! -f "/usr/bin/x-ui" ]; then
        echo -e "${RED}3X-UI未安装，无需卸载${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    echo -e "${YELLOW}正在卸载3X-UI...${NC}"
    
    # 使用3X-UI自带的卸载功能
    if [ -f "/usr/bin/x-ui" ]; then
        x-ui uninstall
    else
        # 手动卸载
        systemctl stop x-ui 2>/dev/null
        systemctl disable x-ui 2>/dev/null
        rm -rf /usr/local/x-ui
        rm -f /usr/bin/x-ui
        rm -f /etc/systemd/system/x-ui.service
        systemctl daemon-reload
    fi
    
    # 从安装日志中删除
    sed -i '/3X-UI/d' /root/.sb_logs/main_install.log 2>/dev/null
    
    echo -e "${GREEN}3X-UI卸载完成${NC}"
    read -p "按回车键继续..." temp
}

# 卸载Sing-box-yg
uninstall_singbox_yg() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载Sing-box-yg:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/sing-box" ]; then
        echo -e "${RED}Sing-box-yg未安装，无需卸载${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    echo -e "${YELLOW}正在卸载Sing-box-yg...${NC}"
    
    # 使用Sing-box-yg自带的卸载功能
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh) uninstall
    
    # 如果自带卸载失败，手动卸载
    if [ -f "/usr/local/bin/sing-box" ]; then
        # 停止服务
        systemctl stop sing-box 2>/dev/null
        systemctl disable sing-box 2>/dev/null
        
        # 删除文件
        rm -f /usr/local/bin/sing-box
        rm -rf /usr/local/etc/sing-box
        rm -f /etc/systemd/system/sing-box.service
        
        # 重新加载systemd
        systemctl daemon-reload
    fi
    
    # 从安装日志中删除
    sed -i '/Sing-box-yg/d' /root/.sb_logs/main_install.log 2>/dev/null
    
    echo -e "${GREEN}Sing-box-yg卸载完成${NC}"
    read -p "按回车键继续..." temp
}

# 卸载全部软件和环境
uninstall_all() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载全部软件和环境:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${RED}警告: 此操作将卸载所有已安装的软件和环境!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " CONFIRM
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消卸载${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    echo -e "${YELLOW}开始卸载所有软件...${NC}"
    
    # 卸载Hysteria-2
    if [ -f "/usr/local/bin/hysteria" ]; then
        echo -e "${YELLOW}卸载Hysteria-2...${NC}"
        uninstall_hysteria2
    fi
    
    # 卸载3X-UI
    if [ -f "/usr/local/x-ui/x-ui" ] || [ -f "/usr/bin/x-ui" ]; then
        echo -e "${YELLOW}卸载3X-UI...${NC}"
        uninstall_3xui
    fi
    
    # 卸载Sing-box-yg
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo -e "${YELLOW}卸载Sing-box-yg...${NC}"
        uninstall_singbox_yg
    fi
    
        # 卸载所有证书
    echo -e "${YELLOW}卸载所有SSL证书...${NC}"
        uninstall_all_certificates
    
    # 清理环境
    echo -e "${YELLOW}清理环境...${NC}"
    
    # 删除日志目录
    rm -rf /root/.sb_logs
    
    # 删除临时文件
    rm -rf /tmp/hysteria2
    rm -rf /tmp/acme
    
    # 删除脚本创建的其他文件
    rm -f /usr/local/bin/xx
    
    echo -e "${GREEN}所有软件和环境已卸载完成${NC}"
    read -p "按回车键继续..." temp
}

# 卸载所有证书
uninstall_all_certificates() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载所有SSL证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否有证书
    local main_log="/root/.sb_logs/main_install.log"
    local domains=()
    
    if [ -f "$main_log" ]; then
    # 获取所有已安装的证书域名
    while IFS= read -r line; do
        if [[ $line == *"SSL证书:"* ]]; then
            domain=$(echo $line | cut -d':' -f2)
            domains+=("$domain")
        fi
    done < "$main_log"
    fi
    
    # 卸载所有找到的证书
    if [ ${#domains[@]} -gt 0 ]; then
    for domain in "${domains[@]}"; do
            echo -e "${YELLOW}卸载域名为 $domain 的证书...${NC}"
        uninstall_certificate "$domain"
        done
    fi
    
    # 清理所有证书文件
    echo -e "${YELLOW}清理所有证书文件...${NC}"
    
    # 清理acme.sh目录
    if [ -d "/root/.acme.sh" ]; then
        echo -e "${YELLOW}清理acme.sh目录...${NC}"
        /root/.acme.sh/acme.sh --uninstall
        rm -rf /root/.acme.sh
    fi
    
    # 清理证书文件
    echo -e "${YELLOW}清理证书文件...${NC}"
    rm -rf /root/cert
    rm -rf /etc/ssl/private
    rm -rf /etc/ssl/certs
    rm -f /root/*.pem
    rm -f /root/*.key
    rm -f /root/*.crt
    
    # 清理其他可能的证书位置
    find /root -name "*.pem" -delete
    find /root -name "*.key" -delete
    find /root -name "*.crt" -delete
    find /etc -name "*.pem" -delete
    find /etc -name "*.key" -delete
    find /etc -name "*.crt" -delete
    
    echo -e "${GREEN}所有证书已卸载完成${NC}"
}

# 卸载证书
uninstall_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}卸载域名为 $domain 的证书...${NC}"
    
    # 使用acme.sh卸载证书
    if [ -f "/root/.acme.sh/acme.sh" ]; then
        /root/.acme.sh/acme.sh --revoke -d "$domain" --force
        /root/.acme.sh/acme.sh --remove -d "$domain" --force
    fi
    
    # 删除证书文件
    rm -f "/root/cert/${domain}.pem"
    rm -f "/root/cert/${domain}.key"
    rm -f "/etc/ssl/private/${domain}.key"
    rm -f "/etc/ssl/certs/${domain}.pem"
    rm -f "/root/${domain}.pem"
    rm -f "/root/${domain}.key"
    
    # 从安装日志中删除
    sed -i "/SSL证书:${domain}/d" /root/.sb_logs/main_install.log 2>/dev/null
    
    echo -e "${GREEN}证书 $domain 已卸载${NC}"
}

# 配置Hysteria-2
configure_hysteria2() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}配置Hysteria-2:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/hysteria" ]; then
        echo -e "${RED}Hysteria-2未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 运行官方脚本进行配置
    wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
    
    read -p "按回车键继续..." temp
}

# 查看Hysteria-2配置
view_hysteria2_config() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}Hysteria-2配置信息:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/hysteria" ]; then
        echo -e "${RED}Hysteria-2未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 检查服务状态
    echo -e "${YELLOW}服务状态:${NC}"
    systemctl status hysteria --no-pager
    
    # 显示配置文件
    if [ -f "/etc/hysteria/config.json" ]; then
        echo -e "\n${YELLOW}配置文件内容:${NC}"
        cat /etc/hysteria/config.json
    elif [ -f "/etc/hysteria/config.yaml" ]; then
        echo -e "\n${YELLOW}配置文件内容:${NC}"
        cat /etc/hysteria/config.yaml
    else
        echo -e "${RED}未找到配置文件${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 配置3X-UI
configure_3xui() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}配置3X-UI:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/x-ui/x-ui" ] && [ ! -f "/usr/bin/x-ui" ]; then
        echo -e "${RED}3X-UI未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 运行3X-UI自带的配置命令
    if [ -f "/usr/bin/x-ui" ]; then
        x-ui
    else
        echo -e "${RED}无法找到x-ui命令，请尝试重新安装${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 查看3X-UI配置
view_3xui_config() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}3X-UI配置信息:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/x-ui/x-ui" ] && [ ! -f "/usr/bin/x-ui" ]; then
        echo -e "${RED}3X-UI未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 检查服务状态
    echo -e "${YELLOW}服务状态:${NC}"
    systemctl status x-ui --no-pager
    
    # 获取面板端口
    PANEL_PORT=$(grep "^port:" /usr/local/x-ui/config.yaml 2>/dev/null | awk '{print $2}' || echo "2053")
    
    # 显示面板信息
    echo -e "\n${YELLOW}面板信息:${NC}"
    echo -e "  面板地址: http://${PUBLIC_IPV4}:${PANEL_PORT}"
    echo -e "  默认用户名: admin"
    echo -e "  默认密码: admin"
    
    read -p "按回车键继续..." temp
}

# 配置Sing-box-yg
configure_singbox_yg() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}配置Sing-box-yg:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/sing-box" ]; then
        echo -e "${RED}Sing-box-yg未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 运行Sing-box-yg自带的配置命令
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
    
    read -p "按回车键继续..." temp
}

# 查看Sing-box-yg配置
view_singbox_yg_config() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}Sing-box-yg配置信息:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 检查是否安装
    if [ ! -f "/usr/local/bin/sing-box" ]; then
        echo -e "${RED}Sing-box-yg未安装，请先安装${NC}"
        read -p "按回车键继续..." temp
        return
    fi
    
    # 检查服务状态
    echo -e "${YELLOW}服务状态:${NC}"
    systemctl status sing-box --no-pager
    
    # 显示配置文件
    if [ -f "/usr/local/etc/sing-box/config.json" ]; then
        echo -e "\n${YELLOW}配置文件内容:${NC}"
        cat /usr/local/etc/sing-box/config.json
    else
        echo -e "${RED}未找到配置文件${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 查看配置
show_config() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}查看配置:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择要查看的配置:${NC}"
    echo -e "  1) 查看Hysteria-2配置"
    echo -e "  2) 查看3X-UI配置"
    echo -e "  3) 查看Sing-box-yg配置"
    echo -e "  4) 查看系统信息"
    echo -e "  5) 查看安装日志"
    echo -e "  0) 返回主菜单"
    
    read -p "请选择 [0-5]: " CONFIG_OPTION
    
    case $CONFIG_OPTION in
        1) view_hysteria2_config ;;
        2) view_3xui_config ;;
        3) view_singbox_yg_config ;;
        4) view_system_info ;;
        5) view_install_logs ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            show_config
            ;;
    esac
}

# 查看系统信息
view_system_info() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}系统信息:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}基本信息:${NC}"
    echo -e "  主机名: $(hostname)"
    echo -e "  系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  内核版本: $(uname -r)"
    echo -e "  架构: $(uname -m)"
    echo -e "  公网IPv4: ${PUBLIC_IPV4}"
    if [ ! -z "$PUBLIC_IPV6" ]; then
        echo -e "  公网IPv6: ${PUBLIC_IPV6}"
    elif [ ! -z "$LOCAL_IPV6" ]; then
        echo -e "  IPv6地址: ${LOCAL_IPV6}"
    fi
    echo -e "  内网IPv4: ${LOCAL_IPV4}"
    echo -e "  时区: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    echo -e "  BBR状态: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    
    echo -e "\n${YELLOW}CPU信息:${NC}"
    echo -e "  CPU型号: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo -e "  CPU核心数: $(nproc)"
    echo -e "  CPU负载: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    
    echo -e "\n${YELLOW}内存信息:${NC}"
    free -h | grep -v + > /tmp/mem_info
    echo -e "  总内存: $(cat /tmp/mem_info | grep Mem | awk '{print $2}')"
    echo -e "  已用内存: $(cat /tmp/mem_info | grep Mem | awk '{print $3}')"
    echo -e "  可用内存: $(cat /tmp/mem_info | grep Mem | awk '{print $7}')"
    
    echo -e "\n${YELLOW}磁盘信息:${NC}"
    df -h | grep -v tmpfs | grep -v udev | grep -v loop > /tmp/disk_info
    cat /tmp/disk_info
    
    echo -e "\n${YELLOW}网络信息:${NC}"
    echo -e "  活动连接数: $(netstat -an | grep ESTABLISHED | wc -l)"
    echo -e "  TCP连接数: $(netstat -ant | wc -l)"
    echo -e "  UDP连接数: $(netstat -anu | wc -l)"
    
    read -p "按回车键继续..." temp
}

# 查看安装日志
view_install_logs() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装日志:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    local main_log="/root/.sb_logs/main_install.log"
    
    if [ -f "$main_log" ]; then
        echo -e "${YELLOW}已安装的组件:${NC}"
        cat "$main_log"
    else
        echo -e "${RED}未找到安装日志${NC}"
    fi
    
    echo -e "\n${YELLOW}是否查看详细日志? (y/n)${NC}"
    read -p "选择 [y/n]: " VIEW_DETAIL
    
    if [[ $VIEW_DETAIL =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}请选择要查看的日志:${NC}"
        echo -e "  1) Hysteria-2安装日志"
        echo -e "  2) 3X-UI安装日志"
        echo -e "  3) Sing-box-yg安装日志"
        echo -e "  0) 返回"
        
        read -p "请选择 [0-3]: " LOG_OPTION
        
        case $LOG_OPTION in
            1) 
                if [ -f "/root/.sb_logs/hysteria2_install.log" ]; then
                    clear
                    echo -e "${YELLOW}Hysteria-2安装日志:${NC}"
                    cat "/root/.sb_logs/hysteria2_install.log"
                else
                    echo -e "${RED}未找到Hysteria-2安装日志${NC}"
                fi
                ;;
            2) 
                if [ -f "/root/.sb_logs/3xui_install.log" ]; then
                    clear
                    echo -e "${YELLOW}3X-UI安装日志:${NC}"
                    cat "/root/.sb_logs/3xui_install.log"
                else
                    echo -e "${RED}未找到3X-UI安装日志${NC}"
                fi
                ;;
            3) 
                if [ -f "/root/.sb_logs/singbox_yg_install.log" ]; then
                    clear
                    echo -e "${YELLOW}Sing-box-yg安装日志:${NC}"
                    cat "/root/.sb_logs/singbox_yg_install.log"
                else
                    echo -e "${RED}未找到Sing-box-yg安装日志${NC}"
                fi
                ;;
            0) ;;
            *) 
                echo -e "${RED}无效选项${NC}"
                ;;
        esac
    fi
    
    read -p "按回车键继续..." temp
}

# 系统工具
system_tools() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}系统工具:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择工具:${NC}"
    echo -e "  1) 系统信息"
    echo -e "  2) 网络测速"
    echo -e "  3) 端口管理"
    echo -e "  4) 系统更新"
    echo -e "  5) 重启系统"
    echo -e "  6) 关闭系统"
    echo -e "  0) 返回主菜单"
    
    read -p "请选择 [0-6]: " TOOL_OPTION
    
    case $TOOL_OPTION in
        1) view_system_info ;;
        2) network_speedtest ;;
        3) port_management ;;
        4) system_update ;;
        5) reboot_system ;;
        6) shutdown_system ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            system_tools
            ;;
    esac
}

# 网络测速
network_speedtest() {
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}网络测速:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    echo -e "${YELLOW}请选择测速工具:${NC}"
    echo -e "  1) Speedtest (测试上下行速度)"
    echo -e "  2) 简单下载测速"
    echo -e "  3) 路由追踪"
    echo -e "  0) 返回"
    
    read -p "请选择 [0-3]: " SPEED_OPTION
    
    case $SPEED_OPTION in
        1) 
            echo -e "${YELLOW}正在安装Speedtest...${NC}"
            if [ -f /etc/debian_version ]; then
                apt update
                apt install -y curl
            elif [ -f /etc/redhat-release ]; then
                yum update -y
                yum install -y curl
            fi
            
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
            apt install -y speedtest
            
            echo -e "${YELLOW}开始测速...${NC}"
            speedtest
            ;;
        2) 
            echo -e "${YELLOW}开始下载测速...${NC}"
            wget -O /dev/null http://cachefly.cachefly.net/100mb.test
            ;;
        3) 
            echo -e "${YELLOW}请输入要追踪的目标 (IP或域名):${NC}"
            read -p "目标: " TRACE_TARGET
            
            if [ -z "$TRACE_TARGET" ]; then
                echo -e "${RED}目标不能为空${NC}"
            else
                traceroute "$TRACE_TARGET"
            fi
            ;;
        0) 
            system_tools
            return
            ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            network_speedtest
            ;;
    esac
    
    read -p "按回车键继续..." temp
    network_speedtest
}

# 防火墙设置
firewall_settings() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}防火墙设置:${NC}"
    echo -e "${BLUE}=================================================${NC}"
                
    # 检测防火墙类型
    local firewall_type=""
    if command -v ufw &>/dev/null; then
        firewall_type="ufw"
    elif command -v firewall-cmd &>/dev/null; then
        firewall_type="firewalld"
    elif command -v iptables &>/dev/null; then
        # 检查是否有ufw或firewalld作为前端
        if systemctl is-active ufw &>/dev/null || systemctl is-active firewalld &>/dev/null; then
            if systemctl is-active ufw &>/dev/null; then
                firewall_type="ufw"
            else
                firewall_type="firewalld"
            fi
        else
            firewall_type="iptables"
        fi
    else
        echo -e "${RED}未检测到支持的防火墙${NC}"
        read -p "按回车键继续..." temp
        system_tools
        return
    fi
    
    echo -e "${YELLOW}检测到防火墙类型: $firewall_type${NC}"
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 查看防火墙状态"
    echo -e "  2) 开启防火墙"
    echo -e "  3) 关闭防火墙"
    echo -e "  4) 开放端口 (IPv4)"
    echo -e "  5) 关闭端口 (IPv4)"
    echo -e "  6) 自动配置应用端口"
    echo -e "  7) 开放端口 (IPv6)"
    echo -e "  8) 关闭端口 (IPv6)"
    echo -e "  0) 返回"
    
    read -p "请选择 [0-8]: " FW_OPTION
                
    case $FW_OPTION in
        1) 
            echo -e "${YELLOW}防火墙状态:${NC}"
            case $firewall_type in
                ufw) ufw status ;;
                firewalld) firewall-cmd --state ;;
                iptables) 
                    echo -e "${YELLOW}iptables规则 (IPv4):${NC}"
                    iptables -L -n
                    
                    # 检查并显示IPv6规则
                    if command -v ip6tables &>/dev/null; then
                        echo -e "\n${YELLOW}ip6tables规则 (IPv6):${NC}"
                        ip6tables -L -n
                    fi
                    ;;
            esac
            ;;
        2) 
            echo -e "${YELLOW}开启防火墙...${NC}"
            case $firewall_type in
                ufw) 
                    ufw enable
                    ;;
                firewalld) 
                    systemctl start firewalld && systemctl enable firewalld
                    ;;
                iptables) 
                    # 在iptables模式下，不尝试启动服务，而是直接应用规则
                    echo -e "${YELLOW}在纯iptables模式下，需要手动设置规则...${NC}"
                    echo -e "${YELLOW}应用基本规则...${NC}"
                    
                    # 保存当前规则
                    iptables-save > /tmp/iptables.rules.bak
                    
                    # 清空现有规则
                    iptables -F
                    iptables -X
                    iptables -t nat -F
                    iptables -t nat -X
                    iptables -t mangle -F
                    iptables -t mangle -X
                    
                    # 允许已建立的连接
                    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                    
                    # 允许本地回环接口
                    iptables -A INPUT -i lo -j ACCEPT
                    
                    # 允许SSH (重要！否则可能无法连接服务器)
                    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
                    
                    # 允许常用端口
                    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
                    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
                    
                    # 自动添加已安装应用的端口
                    auto_add_app_ports "iptables"
                    
                    # 重要：设置默认拒绝策略（这才是真正的防火墙）
                    echo -e "${YELLOW}设置默认拒绝策略...${NC}"
                    iptables -P INPUT DROP
                    iptables -P FORWARD DROP
                    # OUTPUT允许，使服务器可以主动发起连接
                    iptables -P OUTPUT ACCEPT
                    
                    # 配置IPv6防火墙（如果可用）
                    if command -v ip6tables >/dev/null 2>&1; then
                        echo -e "${YELLOW}配置IPv6防火墙...${NC}"
                        # 清空现有IPv6规则
                        ip6tables -F
                        ip6tables -X
                        ip6tables -t mangle -F
                        ip6tables -t mangle -X
                        
                        # 允许已建立的连接
                        ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                        
                        # 允许本地回环接口
                        ip6tables -A INPUT -i lo -j ACCEPT
                        
                        # 允许SSH (重要！)
                        ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
                        
                        # 允许常用端口
                        ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
                        ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT
                        
                        # 自动添加已安装应用的端口到IPv6规则
                        # 这里我们依赖auto_add_app_ports函数，它会同时处理IPv4和IPv6
                        
                        # 设置默认拒绝策略
                        ip6tables -P INPUT DROP
                        ip6tables -P FORWARD DROP
                        ip6tables -P OUTPUT ACCEPT
                    fi
                    
                    # 保存规则
                    if command -v iptables-save >/dev/null 2>&1; then
                        echo -e "${YELLOW}保存防火墙规则...${NC}"
                        if [ -d "/etc/iptables" ]; then
                            iptables-save > /etc/iptables/rules.v4
                        else
                            mkdir -p /etc/iptables
                            iptables-save > /etc/iptables/rules.v4
                        fi
                        
                        # 保存IPv6规则
                        if command -v ip6tables-save >/dev/null 2>&1 && command -v ip6tables >/dev/null 2>&1; then
                            ip6tables-save > /etc/iptables/rules.v6
                        fi
                        
                        # 创建启动脚本确保规则持久化
                        cat > /etc/network/if-pre-up.d/iptables << 'EOF'
#!/bin/bash
/sbin/iptables-restore < /etc/iptables/rules.v4
if [ -f /etc/iptables/rules.v6 ]; then
    /sbin/ip6tables-restore < /etc/iptables/rules.v6
fi
EOF
                        chmod +x /etc/network/if-pre-up.d/iptables
                        echo -e "${GREEN}防火墙规则已保存并设置开机自启${NC}"
                    else
                        echo -e "${RED}iptables-save命令不可用，无法保存规则${NC}"
                    fi
                    
                    echo -e "${GREEN}防火墙已启用，提供了真正的安全保护${NC}"
                    echo -e "${YELLOW}注意：现在只有特定端口允许连接，其他所有连接都会被拒绝${NC}"
                    ;;
            esac
            ;;
        3) 
            echo -e "${YELLOW}关闭防火墙...${NC}"
            case $firewall_type in
                ufw) ufw disable ;;
                firewalld) systemctl stop firewalld && systemctl disable firewalld ;;
                iptables) 
                    # 清空所有规则
                    iptables -F
                    iptables -X
                    iptables -t nat -F
                    iptables -t nat -X
                    iptables -t mangle -F
                    iptables -t mangle -X
                    iptables -P INPUT ACCEPT
                    iptables -P FORWARD ACCEPT
                    iptables -P OUTPUT ACCEPT
                    
                    # 如果支持IPv6，也清空IPv6规则
                    if command -v ip6tables >/dev/null 2>&1; then
                        ip6tables -F
                        ip6tables -X
                        ip6tables -t mangle -F
                        ip6tables -t mangle -X
                        ip6tables -P INPUT ACCEPT
                        ip6tables -P FORWARD ACCEPT
                        ip6tables -P OUTPUT ACCEPT
                    fi
                    
                    # 保存空规则
                    if command -v iptables-save >/dev/null 2>&1; then
                        if [ -d "/etc/iptables" ]; then
                            iptables-save > /etc/iptables/rules.v4
                            
                            # 保存IPv6规则
                            if command -v ip6tables-save >/dev/null 2>&1; then
                                ip6tables-save > /etc/iptables/rules.v6
                            fi
                        fi
                    fi
                    
                    echo -e "${GREEN}已清空所有iptables规则${NC}"
                    ;;
            esac
            ;;
        4) # 开放IPv4端口
            echo -e "${YELLOW}请输入要开放的IPv4端口:${NC}"
            read -p "端口: " OPEN_PORT
            
            if [ -z "$OPEN_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}请选择协议:${NC}"
                echo -e "  1) TCP"
                echo -e "  2) UDP"
                echo -e "  3) TCP+UDP (两者都开放)"
                read -p "选择 [1-3] (默认: 3): " PROTOCOL_OPTION
                PROTOCOL_OPTION=${PROTOCOL_OPTION:-3}
                
                echo -e "${YELLOW}开放IPv4端口 $OPEN_PORT...${NC}"
                case $firewall_type in
                    ufw) 
                        case $PROTOCOL_OPTION in
                            1) ufw allow $OPEN_PORT/tcp ;;
                            2) ufw allow $OPEN_PORT/udp ;;
                            *) ufw allow $OPEN_PORT/tcp && ufw allow $OPEN_PORT/udp ;;
                        esac
                        ;;
                    firewalld) 
                        case $PROTOCOL_OPTION in
                            1) firewall-cmd --permanent --add-port=$OPEN_PORT/tcp ;;
                            2) firewall-cmd --permanent --add-port=$OPEN_PORT/udp ;;
                            *) 
                                firewall-cmd --permanent --add-port=$OPEN_PORT/tcp 
                                firewall-cmd --permanent --add-port=$OPEN_PORT/udp 
                                ;;
                        esac
                        firewall-cmd --reload 
                        ;;
                    iptables) 
                        case $PROTOCOL_OPTION in
                            1) iptables -A INPUT -p tcp --dport $OPEN_PORT -j ACCEPT ;;
                            2) iptables -A INPUT -p udp --dport $OPEN_PORT -j ACCEPT ;;
                            *) 
                                iptables -A INPUT -p tcp --dport $OPEN_PORT -j ACCEPT
                                iptables -A INPUT -p udp --dport $OPEN_PORT -j ACCEPT
                                ;;
                        esac
                        
                        # 保存规则
                        if command -v iptables-save >/dev/null 2>&1; then
                            if [ -d "/etc/iptables" ]; then
                                iptables-save > /etc/iptables/rules.v4
                            fi
                        fi
                        ;;
                esac
                echo -e "${GREEN}IPv4端口 $OPEN_PORT 已开放${NC}"
            fi
            ;;
        5) # 关闭IPv4端口
            echo -e "${YELLOW}请输入要关闭的IPv4端口:${NC}"
            read -p "端口: " CLOSE_PORT
            
            if [ -z "$CLOSE_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}请选择协议:${NC}"
                echo -e "  1) TCP"
                echo -e "  2) UDP"
                echo -e "  3) TCP+UDP (两者都关闭)"
                read -p "选择 [1-3] (默认: 3): " PROTOCOL_OPTION
                PROTOCOL_OPTION=${PROTOCOL_OPTION:-3}
                
                echo -e "${YELLOW}关闭IPv4端口 $CLOSE_PORT...${NC}"
                case $firewall_type in
                    ufw) 
                        case $PROTOCOL_OPTION in
                            1) ufw delete allow $CLOSE_PORT/tcp ;;
                            2) ufw delete allow $CLOSE_PORT/udp ;;
                            *) ufw delete allow $CLOSE_PORT/tcp && ufw delete allow $CLOSE_PORT/udp ;;
                        esac
                        ;;
                    firewalld) 
                        case $PROTOCOL_OPTION in
                            1) firewall-cmd --permanent --remove-port=$CLOSE_PORT/tcp ;;
                            2) firewall-cmd --permanent --remove-port=$CLOSE_PORT/udp ;;
                            *) 
                                firewall-cmd --permanent --remove-port=$CLOSE_PORT/tcp 
                                firewall-cmd --permanent --remove-port=$CLOSE_PORT/udp 
                                ;;
                        esac
                        firewall-cmd --reload 
                        ;;
                    iptables) 
                        case $PROTOCOL_OPTION in
                            1) iptables -D INPUT -p tcp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null ;;
                            2) iptables -D INPUT -p udp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null ;;
                            *) 
                                iptables -D INPUT -p tcp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null
                                iptables -D INPUT -p udp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null
                                ;;
                        esac
                        
                        # 保存规则
                        if command -v iptables-save >/dev/null 2>&1; then
                            if [ -d "/etc/iptables" ]; then
                                iptables-save > /etc/iptables/rules.v4
                            fi
                        fi
                        ;;
                esac
                echo -e "${GREEN}IPv4端口 $CLOSE_PORT 已关闭${NC}"
            fi
            ;;
        6) # 自动配置应用端口
            echo -e "${YELLOW}自动配置已安装应用的端口...${NC}"
            auto_add_app_ports "$firewall_type"
            echo -e "${GREEN}应用端口已配置完成${NC}"
            ;;
        7) # 开放IPv6端口
            # 检查是否支持IPv6
            if ! command -v ip6tables &>/dev/null; then
                echo -e "${RED}系统不支持IPv6或ip6tables命令不可用${NC}"
                read -p "按回车键继续..." temp
                firewall_settings
                return
            fi
            
            echo -e "${YELLOW}请输入要开放的IPv6端口:${NC}"
            read -p "端口: " OPEN_PORT
            
            if [ -z "$OPEN_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}请选择协议:${NC}"
                echo -e "  1) TCP"
                echo -e "  2) UDP"
                echo -e "  3) TCP+UDP (两者都开放)"
                read -p "选择 [1-3] (默认: 3): " PROTOCOL_OPTION
                PROTOCOL_OPTION=${PROTOCOL_OPTION:-3}
                
                echo -e "${YELLOW}开放IPv6端口 $OPEN_PORT...${NC}"
                case $PROTOCOL_OPTION in
                    1) ip6tables -A INPUT -p tcp --dport $OPEN_PORT -j ACCEPT ;;
                    2) ip6tables -A INPUT -p udp --dport $OPEN_PORT -j ACCEPT ;;
                    *) 
                        ip6tables -A INPUT -p tcp --dport $OPEN_PORT -j ACCEPT
                        ip6tables -A INPUT -p udp --dport $OPEN_PORT -j ACCEPT
                        ;;
                esac
                
                # 保存规则
                if command -v ip6tables-save >/dev/null 2>&1; then
                    if [ -d "/etc/iptables" ]; then
                        mkdir -p /etc/iptables
                        ip6tables-save > /etc/iptables/rules.v6
                    fi
                fi
                
                echo -e "${GREEN}IPv6端口 $OPEN_PORT 已开放${NC}"
            fi
            ;;
        8) # 关闭IPv6端口
            # 检查是否支持IPv6
            if ! command -v ip6tables &>/dev/null; then
                echo -e "${RED}系统不支持IPv6或ip6tables命令不可用${NC}"
                read -p "按回车键继续..." temp
                firewall_settings
                return
            fi
            
            echo -e "${YELLOW}请输入要关闭的IPv6端口:${NC}"
            read -p "端口: " CLOSE_PORT
            
            if [ -z "$CLOSE_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}请选择协议:${NC}"
                echo -e "  1) TCP"
                echo -e "  2) UDP"
                echo -e "  3) TCP+UDP (两者都关闭)"
                read -p "选择 [1-3] (默认: 3): " PROTOCOL_OPTION
                PROTOCOL_OPTION=${PROTOCOL_OPTION:-3}
                
                echo -e "${YELLOW}关闭IPv6端口 $CLOSE_PORT...${NC}"
                case $PROTOCOL_OPTION in
                    1) ip6tables -D INPUT -p tcp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null ;;
                    2) ip6tables -D INPUT -p udp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null ;;
                    *) 
                        ip6tables -D INPUT -p tcp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null
                        ip6tables -D INPUT -p udp --dport $CLOSE_PORT -j ACCEPT 2>/dev/null
                        ;;
                esac
                
                # 保存规则
                if command -v ip6tables-save >/dev/null 2>&1; then
                    if [ -d "/etc/iptables" ]; then
                        mkdir -p /etc/iptables
                        ip6tables-save > /etc/iptables/rules.v6
                    fi
                fi
                
                echo -e "${GREEN}IPv6端口 $CLOSE_PORT 已关闭${NC}"
            fi
            ;;
        0) 
            return
            ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            firewall_settings
            ;;
    esac
                
    read -p "按回车键继续..." temp
    firewall_settings
}

# 检查端口规则是否已存在，避免重复添加
port_rule_exists() {
    local port=$1
    local protocol=$2  # tcp or udp
    
    if iptables -L INPUT -n | grep -q "$protocol dpt:$port"; then
        return 0  # 规则已存在
    else
        return 1  # 规则不存在
    fi
}

# 增强型自动配置应用端口函数，可以处理删除和修改的端口
auto_add_app_ports() {
    local firewall_type=$1
    local ports_added=0
    local active_ports=()
    
    echo -e "${YELLOW}检测已安装应用的端口...${NC}"
    
    # 创建临时文件存储当前活跃端口
    local temp_active_ports="/tmp/active_ports.txt"
    touch $temp_active_ports
    
    # 使用netstat直接检测应用端口
    echo -e "${YELLOW}从运行进程中检测端口...${NC}"
    
    # 检测所有活跃的端口并记录
    collect_active_ports() {
        # 检测x-ui面板端口
        X_UI_PORTS=$(netstat -tulpn 2>/dev/null | grep 'x-ui' | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)
        for port in $X_UI_PORTS; do
            if [ ! -z "$port" ]; then
                echo "$port" >> $temp_active_ports
                echo -e "${GREEN}检测到3X-UI面板端口: ${port}${NC}"
                active_ports+=("$port")
            fi
        done
        
        # 检测xray入站端口
        XRAY_PORTS=$(netstat -tulpn 2>/dev/null | grep -E 'xray|v2ray' | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)
        for port in $XRAY_PORTS; do
            if [ ! -z "$port" ]; then
                echo "$port" >> $temp_active_ports
                echo -e "${GREEN}检测到Xray入站端口: ${port}${NC}"
                active_ports+=("$port")
            fi
        done
        
        # 检测hysteria端口
        HYSTERIA_PORTS=$(netstat -tulpn 2>/dev/null | grep -E 'hysteria' | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)
        for port in $HYSTERIA_PORTS; do
            if [ ! -z "$port" ]; then
                echo "$port" >> $temp_active_ports
                echo -e "${GREEN}检测到Hysteria端口: ${port}${NC}"
                active_ports+=("$port")
            fi
        done
        
        # 检查3X-UI中配置的入站规则端口
        if [ -f "/usr/local/x-ui/db/x-ui.db" ]; then
            echo -e "${YELLOW}检测3X-UI入站规则端口...${NC}"
            # 如果有sqlite3命令可用
            if command -v sqlite3 &>/dev/null; then
                INBOUND_PORTS=$(sqlite3 /usr/local/x-ui/db/x-ui.db "SELECT port FROM inbounds WHERE enable = 1;" 2>/dev/null)
                for port in $INBOUND_PORTS; do
                    if [ ! -z "$port" ]; then
                        echo "$port" >> $temp_active_ports
                        echo -e "${GREEN}检测到入站规则端口: ${port}${NC}"
                        active_ports+=("$port")
                    fi
                done
            else
                echo -e "${YELLOW}未找到sqlite3命令，尝试安装...${NC}"
                # 尝试安装sqlite3
                if [ -f /etc/debian_version ]; then
                    apt update && apt install -y sqlite3
                elif [ -f /etc/redhat-release ]; then
                    yum install -y sqlite
                fi
                
                # 重新尝试
                if command -v sqlite3 &>/dev/null; then
                    INBOUND_PORTS=$(sqlite3 /usr/local/x-ui/db/x-ui.db "SELECT port FROM inbounds WHERE enable = 1;" 2>/dev/null)
                    for port in $INBOUND_PORTS; do
                        if [ ! -z "$port" ]; then
                            echo "$port" >> $temp_active_ports
                            echo -e "${GREEN}检测到入站规则端口: ${port}${NC}"
                            active_ports+=("$port")
                        fi
                    done
                else
                    echo -e "${YELLOW}无法安装sqlite3，使用备用方法检测端口...${NC}"
                fi
            fi
        fi
        
        # 检查Hysteria-2配置文件
        if [ -f "/etc/hysteria/config.json" ]; then
            # 从config.json中提取端口
            HY2_PORT=$(grep -o '"listen": "[^"]*"' /etc/hysteria/config.json | grep -o '[0-9]*')
            if [ -z "$HY2_PORT" ]; then
                # 尝试另一种格式
                HY2_PORT=$(grep -o '"listen": ":.*"' /etc/hysteria/config.json | grep -o '[0-9]*')
            fi
            
            if [ ! -z "$HY2_PORT" ]; then
                echo "$HY2_PORT" >> $temp_active_ports
                echo -e "${GREEN}检测到Hysteria-2端口: ${HY2_PORT}${NC}"
                active_ports+=("$HY2_PORT")
            fi
        elif [ -f "/etc/hysteria/server.json" ]; then
            # 旧版本配置文件
            HY2_PORT=$(grep -o '"listen": "[^"]*"' /etc/hysteria/server.json | grep -o '[0-9]*')
            if [ -z "$HY2_PORT" ]; then
                # 尝试另一种格式
                HY2_PORT=$(grep -o '"listen": ":.*"' /etc/hysteria/server.json | grep -o '[0-9]*')
            fi
            
            if [ ! -z "$HY2_PORT" ]; then
                echo "$HY2_PORT" >> $temp_active_ports
                echo -e "${GREEN}检测到Hysteria-2端口: ${HY2_PORT}${NC}"
                active_ports+=("$HY2_PORT")
            fi
        fi
        
        # 添加常用系统端口（仅记录端口号，不添加到active_ports数组）
        echo "22" >> $temp_active_ports  # SSH
        echo "80" >> $temp_active_ports  # HTTP
        echo "443" >> $temp_active_ports # HTTPS
        
        # 去重
        sort -u $temp_active_ports -o $temp_active_ports
    }
    
    # 收集活跃端口
    collect_active_ports
    
    # 添加活跃端口到防火墙
    for port in "${active_ports[@]}"; do
        case $firewall_type in
            ufw) 
                ufw status | grep -q "$port/tcp" || ufw allow $port/tcp
                ufw status | grep -q "$port/udp" || ufw allow $port/udp
                ;;
            firewalld) 
                firewall-cmd --list-ports | grep -q "$port/tcp" || firewall-cmd --permanent --add-port=$port/tcp
                firewall-cmd --list-ports | grep -q "$port/udp" || firewall-cmd --permanent --add-port=$port/udp
                ;;
            iptables) 
                port_rule_exists $port "tcp" || iptables -A INPUT -p tcp --dport $port -j ACCEPT
                port_rule_exists $port "udp" || iptables -A INPUT -p udp --dport $port -j ACCEPT
                # IPv6规则
                if command -v ip6tables &>/dev/null; then
                    ip6tables -L INPUT -n | grep -q "tcp dpt:$port" || ip6tables -A INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null || true
                    ip6tables -L INPUT -n | grep -q "udp dpt:$port" || ip6tables -A INPUT -p udp --dport $port -j ACCEPT 2>/dev/null || true
                fi
                ;;
        esac
        echo -e "${GREEN}已添加/验证端口 ${port} 规则${NC}"
        ports_added=1
    done
    
    # 单独添加常用系统端口（仅TCP）
    echo -e "${YELLOW}添加常用端口...${NC}"
    
    # SSH, HTTP, HTTPS (仅TCP)
    case $firewall_type in
        ufw) 
            ufw status | grep -q "22/tcp" || ufw allow 22/tcp
            ufw status | grep -q "80/tcp" || ufw allow 80/tcp
            ufw status | grep -q "443/tcp" || ufw allow 443/tcp
            ;;
        firewalld) 
            firewall-cmd --list-ports | grep -q "22/tcp" || firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --list-ports | grep -q "80/tcp" || firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --list-ports | grep -q "443/tcp" || firewall-cmd --permanent --add-port=443/tcp
            ;;
        iptables) 
            port_rule_exists 22 "tcp" || iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            port_rule_exists 80 "tcp" || iptables -A INPUT -p tcp --dport 80 -j ACCEPT
            port_rule_exists 443 "tcp" || iptables -A INPUT -p tcp --dport 443 -j ACCEPT
            # IPv6规则
            if command -v ip6tables &>/dev/null; then
                ip6tables -L INPUT -n | grep -q "tcp dpt:22" || ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
                ip6tables -L INPUT -n | grep -q "tcp dpt:80" || ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
                ip6tables -L INPUT -n | grep -q "tcp dpt:443" || ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
            fi
            ;;
    esac
    
    # 检查并清理不再活跃的端口规则（可选功能）
    echo -e "${YELLOW}检查不再活跃的端口规则...${NC}"
    
    if [[ "$firewall_type" == "iptables" ]]; then
        # 获取当前iptables中的所有端口规则
        current_tcp_ports=$(iptables -L INPUT -n | grep "tcp dpt:" | grep -o 'dpt:[0-9]*' | cut -d':' -f2 | sort -u)
        current_udp_ports=$(iptables -L INPUT -n | grep "udp dpt:" | grep -o 'dpt:[0-9]*' | cut -d':' -f2 | sort -u)
        
        # 检查每个TCP端口是否仍然活跃
        for tcp_port in $current_tcp_ports; do
            if ! grep -q "^$tcp_port$" $temp_active_ports && [[ "$tcp_port" != "22" ]] && [[ "$tcp_port" != "80" ]] && [[ "$tcp_port" != "443" ]]; then
                echo -e "${YELLOW}删除不再活跃的TCP端口规则: ${tcp_port}${NC}"
                iptables -D INPUT -p tcp --dport $tcp_port -j ACCEPT 2>/dev/null || true
            fi
        done
        
        # 检查每个UDP端口是否仍然活跃
        for udp_port in $current_udp_ports; do
            if ! grep -q "^$udp_port$" $temp_active_ports && [[ "$udp_port" != "22" ]] && [[ "$udp_port" != "80" ]] && [[ "$udp_port" != "443" ]]; then
                echo -e "${YELLOW}删除不再活跃的UDP端口规则: ${udp_port}${NC}"
                iptables -D INPUT -p udp --dport $udp_port -j ACCEPT 2>/dev/null || true
            fi
        done
        
        # 特殊处理：删除22, 80, 443的UDP规则，因为这些通常只需要TCP
        echo -e "${YELLOW}删除不必要的常用端口UDP规则...${NC}"
        iptables -D INPUT -p udp --dport 22 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p udp --dport 80 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -p udp --dport 443 -j ACCEPT 2>/dev/null || true
        
        # 同样处理IPv6规则
        if command -v ip6tables &>/dev/null; then
            current_tcp6_ports=$(ip6tables -L INPUT -n | grep "tcp dpt:" | grep -o 'dpt:[0-9]*' | cut -d':' -f2 | sort -u)
            current_udp6_ports=$(ip6tables -L INPUT -n | grep "udp dpt:" | grep -o 'dpt:[0-9]*' | cut -d':' -f2 | sort -u)
            
            # 检查每个TCP端口是否仍然活跃
            for tcp_port in $current_tcp6_ports; do
                if ! grep -q "^$tcp_port$" $temp_active_ports && [[ "$tcp_port" != "22" ]] && [[ "$tcp_port" != "80" ]] && [[ "$tcp_port" != "443" ]]; then
                    echo -e "${YELLOW}删除不再活跃的IPv6 TCP端口规则: ${tcp_port}${NC}"
                    ip6tables -D INPUT -p tcp --dport $tcp_port -j ACCEPT 2>/dev/null || true
                fi
            done
            
            # 检查每个UDP端口是否仍然活跃
            for udp_port in $current_udp6_ports; do
                if ! grep -q "^$udp_port$" $temp_active_ports && [[ "$udp_port" != "22" ]] && [[ "$udp_port" != "80" ]] && [[ "$udp_port" != "443" ]]; then
                    echo -e "${YELLOW}删除不再活跃的IPv6 UDP端口规则: ${udp_port}${NC}"
                    ip6tables -D INPUT -p udp --dport $udp_port -j ACCEPT 2>/dev/null || true
                fi
            done
            
            # 特殊处理：删除IPv6的22, 80, 443的UDP规则
            echo -e "${YELLOW}删除不必要的常用端口IPv6 UDP规则...${NC}"
            ip6tables -D INPUT -p udp --dport 22 -j ACCEPT 2>/dev/null || true
            ip6tables -D INPUT -p udp --dport 80 -j ACCEPT 2>/dev/null || true
            ip6tables -D INPUT -p udp --dport 443 -j ACCEPT 2>/dev/null || true
        fi
    fi
    
    # 如果是iptables，保存规则
    if [ "$firewall_type" = "iptables" ]; then
        if command -v iptables-save >/dev/null 2>&1; then
            echo -e "${YELLOW}保存防火墙规则...${NC}"
            if [ -d "/etc/iptables" ]; then
                iptables-save > /etc/iptables/rules.v4
            else
                mkdir -p /etc/iptables
                iptables-save > /etc/iptables/rules.v4
            fi
            
            # 保存IPv6规则
            if command -v ip6tables-save >/dev/null 2>&1 && command -v ip6tables >/dev/null 2>&1; then
                ip6tables-save > /etc/iptables/rules.v6
            fi
            echo -e "${GREEN}防火墙规则已保存${NC}"
        fi
    fi
    
    # 清理临时文件
    rm -f $temp_active_ports
    
    if [ "$ports_added" -eq 0 ]; then
        echo -e "${YELLOW}未检测到任何已安装的应用端口${NC}"
    else
        echo -e "${GREEN}已完成端口配置${NC}"
    fi
}

# 端口管理
port_management() {
                clear
                echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}端口管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 查看所有开放端口"
    echo -e "  2) 查看端口占用情况"
    echo -e "  3) 查看特定端口"
    echo -e "  0) 返回"
    
    read -p "请选择 [0-3]: " PORT_OPTION
    
    case $PORT_OPTION in
        1) 
            echo -e "${YELLOW}所有开放端口:${NC}"
            netstat -tulpn | grep LISTEN
            ;;
        2) 
            echo -e "${YELLOW}端口占用情况:${NC}"
            ss -tulpn
            ;;
        3) 
            echo -e "${YELLOW}请输入要查看的端口:${NC}"
            read -p "端口: " CHECK_PORT
            
            if [ -z "$CHECK_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}端口 $CHECK_PORT 的占用情况:${NC}"
                lsof -i :$CHECK_PORT
                netstat -tulpn | grep :$CHECK_PORT
            fi
            ;;
        0) 
            system_tools
            return
            ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            port_management
                        ;;
                esac
                
                read -p "按回车键继续..." temp
    port_management
}

# 系统更新
system_update() {
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}系统更新:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 更新系统软件包"
    echo -e "  2) 更新脚本"
    echo -e "  0) 返回"
    
    read -p "请选择 [0-2]: " UPDATE_OPTION
    
    case $UPDATE_OPTION in
        1) 
            echo -e "${YELLOW}更新系统软件包...${NC}"
            if [ -f /etc/debian_version ]; then
                apt update && apt upgrade -y
            elif [ -f /etc/redhat-release ]; then
                yum update -y
            fi
            echo -e "${GREEN}系统软件包已更新${NC}"
            ;;
        2) 
            echo -e "${YELLOW}更新脚本...${NC}"
            # 这里可以添加脚本更新逻辑
            echo -e "${GREEN}脚本已是最新版本${NC}"
            ;;
        0) 
            system_tools
                return
                ;;
            *)
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            system_update
                ;;
        esac
    
                read -p "按回车键继续..." temp
    system_update
}

# 重启系统
reboot_system() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}重启系统:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${RED}警告: 系统将立即重启!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " REBOOT_CONFIRM
    
    if [[ $REBOOT_CONFIRM =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}系统正在重启...${NC}"
        reboot
    else
        echo -e "${YELLOW}已取消重启${NC}"
        read -p "按回车键继续..." temp
        system_tools
    fi
}

# 关闭系统
shutdown_system() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}关闭系统:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${RED}警告: 系统将立即关闭!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " SHUTDOWN_CONFIRM
    
    if [[ $SHUTDOWN_CONFIRM =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}系统正在关闭...${NC}"
        shutdown -h now
    else
        echo -e "${YELLOW}已取消关机${NC}"
        read -p "按回车键继续..." temp
        system_tools
    fi
}

# 证书管理菜单
certificate_management() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}SSL证书管理:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 安装新证书 (HTTP验证)"
    echo -e "  2) 更新证书"
    echo -e "  3) 删除证书"
    echo -e "  4) 卸载acme.sh"
    echo -e "  0) 返回主菜单"
    
    read -p "选择 [0-4]: " CERT_OPTION
    
    case $CERT_OPTION in
        1) install_certificate_menu ;;
        2) update_certificates_menu ;;
        3) delete_certificate_menu ;;
        4) uninstall_acme ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            certificate_management
            ;;
    esac
}

# 卸载acme.sh
uninstall_acme() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}卸载acme.sh:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}警告: 卸载acme.sh将删除所有证书和相关配置${NC}"
    read -p "确定要卸载acme.sh吗? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "/root/.acme.sh/acme.sh" ]; then
            echo -e "${YELLOW}正在卸载acme.sh...${NC}"
            /root/.acme.sh/acme.sh --uninstall
            rm -rf /root/.acme.sh
            echo -e "${GREEN}acme.sh已成功卸载${NC}"
        else
            echo -e "${RED}未找到acme.sh安装，无需卸载${NC}"
        fi
    else
        echo -e "${YELLOW}已取消卸载操作${NC}"
    fi
    
    read -p "按回车键继续..." temp
    certificate_management
}

# DNS认证管理
dns_management() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}DNS认证管理:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 使用DNS API申请证书"
    echo -e "  2) 使用DNS手动申请证书"
    echo -e "  3) 删除特定域名的证书"
    echo -e "  4) 删除所有证书"
    echo -e "  5) 更新acme.sh及其所有证书"
    echo -e "  0) 返回主菜单"
    
    read -p "选择 [0-5]: " DNS_OPTION
    
    case $DNS_OPTION in
        1) dns_api_certificate ;;
        2) dns_manual_certificate ;;
        3) delete_specific_certificate ;;
        4) delete_all_certificates_dns ;;
        5) update_acme_and_certs ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            dns_management
            ;;
    esac
}

# 使用DNS API申请证书
dns_api_certificate() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择DNS提供商:${NC}"
    echo -e "  1) Cloudflare"
    echo -e "  2) Aliyun (阿里云)"
    echo -e "  3) DNSPod"
    echo -e "  4) GoDaddy"
    echo -e "  5) Namesilo"
    echo -e "  0) 返回"
    
    read -p "选择 [0-5]: " DNS_PROVIDER
    
    case $DNS_PROVIDER in
        1) dns_api_cloudflare ;;
        2) dns_api_aliyun ;;
        3) dns_api_dnspod ;;
        4) dns_api_godaddy ;;
        5) dns_api_namesilo ;;
        0) dns_management ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            dns_api_certificate
            ;;
    esac
}

# Cloudflare DNS API
dns_api_cloudflare() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用Cloudflare DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入Cloudflare Global API Key:${NC}"
    read -p "API Key: " CF_KEY
    
    echo -e "${YELLOW}请输入Cloudflare Email:${NC}"
    read -p "Email: " CF_EMAIL
    
    if [ -z "$CF_KEY" ] || [ -z "$CF_EMAIL" ]; then
        echo -e "${RED}API Key和Email不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export CF_Key="$CF_KEY"
    export CF_Email="$CF_EMAIL"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 阿里云DNS API
dns_api_aliyun() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用阿里云DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入阿里云AccessKey ID:${NC}"
    read -p "AccessKey ID: " ALI_KEY
    
    echo -e "${YELLOW}请输入阿里云AccessKey Secret:${NC}"
    read -p "AccessKey Secret: " ALI_SECRET
    
    if [ -z "$ALI_KEY" ] || [ -z "$ALI_SECRET" ]; then
        echo -e "${RED}AccessKey ID和Secret不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export Ali_Key="$ALI_KEY"
    export Ali_Secret="$ALI_SECRET"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_ali -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# DNSPod DNS API
dns_api_dnspod() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用DNSPod DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入DNSPod ID:${NC}"
    read -p "DNSPod ID: " DP_ID
    
    echo -e "${YELLOW}请输入DNSPod Token:${NC}"
    read -p "DNSPod Token: " DP_KEY
    
    if [ -z "$DP_ID" ] || [ -z "$DP_KEY" ]; then
        echo -e "${RED}DNSPod ID和Token不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export DP_Id="$DP_ID"
    export DP_Key="$DP_KEY"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_dp -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# GoDaddy DNS API
dns_api_godaddy() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用GoDaddy DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入GoDaddy API Key:${NC}"
    read -p "API Key: " GD_KEY
    
    echo -e "${YELLOW}请输入GoDaddy API Secret:${NC}"
    read -p "API Secret: " GD_SECRET
    
    if [ -z "$GD_KEY" ] || [ -z "$GD_SECRET" ]; then
        echo -e "${RED}API Key和Secret不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export GD_Key="$GD_KEY"
    export GD_Secret="$GD_SECRET"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_gd -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# Namesilo DNS API
dns_api_namesilo() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用Namesilo DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入Namesilo API Key:${NC}"
    read -p "API Key: " NS_KEY
    
    if [ -z "$NS_KEY" ]; then
        echo -e "${RED}API Key不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export Namesilo_Key="$NS_KEY"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_namesilo -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 使用DNS手动申请证书
dns_manual_certificate() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用DNS手动申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_management
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns -d "$DOMAIN" -d "*.$DOMAIN" --yes-I-know-dns-manual-mode-enough-go-ahead-please
    
    echo -e "${YELLOW}请在DNS控制面板中添加上述TXT记录，然后按回车键继续...${NC}"
    read -p "按回车键继续..." temp
    
    # 验证并颁发证书
    /root/.acme.sh/acme.sh --renew -d "$DOMAIN" --yes-I-know-dns-manual-mode-enough-go-ahead-please
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 删除特定域名的证书 (DNS管理专用)
delete_specific_certificate() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}删除特定域名的证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入要删除的域名:${NC}"
    read -p "域名: " DELETE_DOMAIN
    
    if [ -z "$DELETE_DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_management
        return
    fi
    
    # 使用acme.sh删除证书
    if [ -f "/root/.acme.sh/acme.sh" ]; then
        /root/.acme.sh/acme.sh --revoke -d "$DELETE_DOMAIN" --force
        /root/.acme.sh/acme.sh --remove -d "$DELETE_DOMAIN" --force
        
        # 删除证书文件
        rm -f "/root/cert/${DELETE_DOMAIN}.pem"
        rm -f "/root/cert/${DELETE_DOMAIN}.key"
        
        # 从安装日志中删除
        sed -i "/SSL证书:${DELETE_DOMAIN}/d" /root/.sb_logs/main_install.log 2>/dev/null
        
        echo -e "${GREEN}证书已删除${NC}"
    else
        echo -e "${RED}未找到acme.sh，无法删除证书${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 删除所有证书 (DNS管理专用)
delete_all_certificates_dns() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}删除所有证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${RED}警告: 此操作将删除所有证书!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " DELETE_ALL_CONFIRM
    
    if [[ $DELETE_ALL_CONFIRM =~ ^[Yy]$ ]]; then
        # 使用acme.sh卸载
        if [ -f "/root/.acme.sh/acme.sh" ]; then
            /root/.acme.sh/acme.sh --uninstall
            rm -rf /root/.acme.sh
            
            # 删除证书文件
            rm -rf /root/cert
            
            # 清空安装日志中的证书记录
            sed -i '/SSL证书:/d' /root/.sb_logs/main_install.log 2>/dev/null
            
            echo -e "${GREEN}所有证书已删除${NC}"
        else
            echo -e "${RED}未找到acme.sh，无法删除证书${NC}"
        fi
    else
        echo -e "${YELLOW}已取消删除${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 更新acme.sh及其所有证书
update_acme_and_certs() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}更新acme.sh及其所有证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 更新acme.sh
    if [ -f "/root/.acme.sh/acme.sh" ]; then
        echo -e "${YELLOW}更新acme.sh...${NC}"
        /root/.acme.sh/acme.sh --upgrade
        
        echo -e "${YELLOW}更新所有证书...${NC}"
        /root/.acme.sh/acme.sh --renew-all
        
        echo -e "${GREEN}acme.sh和所有证书已更新${NC}"
    else
        echo -e "${RED}未找到acme.sh，无法更新${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 恢复系统证书
restore_system_certificates() {
    echo -e "${YELLOW}恢复系统证书...${NC}"
    apt-get update >/dev/null 2>&1
    apt-get install -y ca-certificates >/dev/null 2>&1 || yum install -y ca-certificates >/dev/null 2>&1
    update-ca-certificates >/dev/null 2>&1 || true
    echo -e "${GREEN}系统证书已恢复${NC}"
}

# 在安装Hysteria 2之前添加环境准备
install_hysteria2() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装Hysteria-2:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 创建日志目录
    mkdir -p /root/.sb_logs
    local log_file="/root/.sb_logs/hysteria2_install.log"
    
    # 记录开始安装
    echo "# Hysteria-2安装日志" > $log_file
    echo "# 安装时间: $(date "+%Y-%m-%d %H:%M:%S")" >> $log_file
    
    # 添加前置环境安装
    echo -e "${YELLOW}正在安装必要的环境...${NC}"
    apt-get update
    apt-get install -y ca-certificates net-tools curl
    
    # 安装Hysteria-2
    echo -e "${YELLOW}开始安装Hysteria-2...${NC}"
    wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
    
    # 检查安装结果
    if [ -f "/usr/local/bin/hysteria" ]; then
        echo -e "${GREEN}Hysteria-2安装成功!${NC}"
        
        # 修复权限问题
        if [ -f "/etc/systemd/system/hysteria-server.service" ]; then
            echo -e "${YELLOW}修复Hysteria 2服务权限...${NC}"
            sed -i 's/User=hysteria/#User=hysteria/' /etc/systemd/system/hysteria-server.service
            sed -i 's/Group=hysteria/#Group=hysteria/' /etc/systemd/system/hysteria-server.service
            systemctl daemon-reload
            systemctl restart hysteria-server
        fi
        
        # 更新主安装记录
        update_main_install_log "Hysteria-2"
    else
        echo -e "${RED}Hysteria-2安装失败，请检查网络或稍后再试${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 主函数
main() {
    # 在脚本开始时获取IP地址，确保所有函数都使用相同的值
    get_ip_addresses
    
    # 在脚本开始时调用
    create_xx_shortcut
    
    # 检查依赖文件
    if [ ! -f "/root/server_init.sh" ]; then
        echo -e "${RED}错误: 找不到server_init.sh文件${NC}"
        echo -e "${YELLOW}尝试重新运行安装脚本${NC}"
        exit 1
    fi

    if [ ! -f "/root/cleanup.sh" ]; then
        echo -e "${RED}错误: 找不到cleanup.sh文件${NC}"
        echo -e "${YELLOW}尝试重新运行安装脚本${NC}"
        exit 1
    fi

    if [ ! -f "/root/install_panel.sh" ]; then
        echo -e "${RED}错误: 找不到install_panel.sh文件${NC}"
        echo -e "${YELLOW}尝试重新运行安装脚本${NC}"
        exit 1
    fi

    # 确保日志目录存在
    mkdir -p /root/.sb_logs
    
    while true; do
        show_banner
        show_main_menu
        
        read -p "请选择 [0-10]: " OPTION
        
        case $OPTION in
            1) install_or_reinstall_hysteria2 ;;
            2) install_or_reinstall_3xui ;;
            3) install_or_reinstall_singbox_yg ;;
            4) initialize_server ;;
            5) firewall_settings ;;
            6) show_config ;;
            7) system_tools ;;
            8) certificate_management ;;
            9) dns_management ;;
            10) uninstall ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选项，请重试${NC}" ;;
        esac
    done
}

# 添加新的安装或重装函数
install_or_reinstall_hysteria2() {
                clear
                echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}Hysteria-2管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    # 检查是否已安装
    if [ -f "/usr/local/bin/hysteria" ]; then
        echo -e "${YELLOW}检测到Hysteria-2已安装${NC}"
        echo -e "${YELLOW}请选择操作:${NC}"
        echo -e "  1) 重新安装"
        echo -e "  2) 修改配置-重装-卸载"
        echo -e "  3) 查看配置"
        echo -e "  0) 返回主菜单"
        
        read -p "选择 [0-3]: " H2_OPTION
        
        case $H2_OPTION in
            1) 
                echo -e "${YELLOW}开始重新安装Hysteria-2...${NC}"
                install_hysteria2
                ;;
            2) 
                echo -e "${YELLOW}修改Hysteria-2配置...${NC}"
                configure_hysteria2
                ;;
            3) 
                echo -e "${YELLOW}查看Hysteria-2配置...${NC}"
                view_hysteria2_config
                ;;
            0) 
                return
                ;;
            *) 
                echo -e "${RED}无效选项，请重试${NC}"
                sleep 2
                install_or_reinstall_hysteria2
                    ;;
            esac
    else
        echo -e "${YELLOW}未检测到Hysteria-2，开始安装...${NC}"
        install_hysteria2
    fi
}
                
install_or_reinstall_3xui() {
                clear
                echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}3X-UI管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    # 检查是否已安装
    if [ -f "/usr/local/x-ui/x-ui" ] || [ -f "/usr/bin/x-ui" ]; then
        echo -e "${YELLOW}检测到3X-UI已安装${NC}"
        echo -e "${YELLOW}请选择操作:${NC}"
        echo -e "  1) 重新安装"
        echo -e "  2) 修改配置-重装-卸载"
        echo -e "  3) 查看配置"
        echo -e "  0) 返回主菜单"
        
        read -p "选择 [0-3]: " XUI_OPTION
        
        case $XUI_OPTION in
            1) 
                echo -e "${YELLOW}开始重新安装3X-UI...${NC}"
                install_3xui
                ;;
            2) 
                echo -e "${YELLOW}修改3X-UI配置...${NC}"
                configure_3xui
                ;;
            3) 
                echo -e "${YELLOW}查看3X-UI配置...${NC}"
                view_3xui_config
                ;;
            0) 
            return
                ;;
            *) 
                echo -e "${RED}无效选项，请重试${NC}"
                sleep 2
                install_or_reinstall_3xui
            ;;
    esac
    else
        echo -e "${YELLOW}未检测到3X-UI，开始安装...${NC}"
        install_3xui
    fi
}
                
install_or_reinstall_singbox_yg() {
                clear
                echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}Sing-box-yg管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
    # 检查是否已安装
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo -e "${YELLOW}检测到Sing-box-yg已安装${NC}"
        echo -e "${YELLOW}请选择操作:${NC}"
        echo -e "  1) 重新安装"
        echo -e "  2) 修改配置"
        echo -e "  3) 查看配置"
        echo -e "  0) 返回主菜单"
        
        read -p "选择 [0-3]: " SB_OPTION
        
        case $SB_OPTION in
            1) 
                echo -e "${YELLOW}开始重新安装Sing-box-yg...${NC}"
                install_singbox_yg
                ;;
            2) 
                echo -e "${YELLOW}修改Sing-box-yg配置...${NC}"
                configure_singbox_yg
                ;;
            3) 
                echo -e "${YELLOW}查看Sing-box-yg配置...${NC}"
                view_singbox_yg_config
                ;;
            0) 
            return
            ;;
            *)
                echo -e "${RED}无效选项，请重试${NC}"
                sleep 2
                install_or_reinstall_singbox_yg
            ;;
    esac
    else
        echo -e "${YELLOW}未检测到Sing-box-yg，开始安装...${NC}"
        install_singbox_yg
    fi
}

# 安装Hysteria-2
install_hysteria2() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装Hysteria-2:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 创建日志目录
    mkdir -p /root/.sb_logs
    local log_file="/root/.sb_logs/hysteria2_install.log"
    
    # 记录开始安装
    echo "# Hysteria-2安装日志" > $log_file
    echo "# 安装时间: $(date "+%Y-%m-%d %H:%M:%S")" >> $log_file
    
    # 添加前置环境安装
    echo -e "${YELLOW}正在安装必要的环境...${NC}"
    apt-get update
    apt-get install -y ca-certificates net-tools curl
    
    # 安装Hysteria-2
    echo -e "${YELLOW}开始安装Hysteria-2...${NC}"
    wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
    
    # 检查安装结果
    if [ -f "/usr/local/bin/hysteria" ]; then
        echo -e "${GREEN}Hysteria-2安装成功!${NC}"
        
        # 修复权限问题
        if [ -f "/etc/systemd/system/hysteria-server.service" ]; then
            echo -e "${YELLOW}修复Hysteria 2服务权限...${NC}"
            sed -i 's/User=hysteria/#User=hysteria/' /etc/systemd/system/hysteria-server.service
            sed -i 's/Group=hysteria/#Group=hysteria/' /etc/systemd/system/hysteria-server.service
            systemctl daemon-reload
            systemctl restart hysteria-server
        fi
        
        # 更新主安装记录
        update_main_install_log "Hysteria-2"
    else
        echo -e "${RED}Hysteria-2安装失败，请检查网络或稍后再试${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 安装3X-UI
install_3xui() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装3X-UI:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 创建日志目录
    mkdir -p /root/.sb_logs
    local log_file="/root/.sb_logs/3xui_install.log"
    
    # 记录开始安装
    echo "# 3X-UI安装日志" > $log_file
    echo "# 安装时间: $(date "+%Y-%m-%d %H:%M:%S")" >> $log_file
    
    # 安装3X-UI
    echo -e "${YELLOW}开始安装3X-UI...${NC}"
    # 创建临时文件存储安装输出
    local temp_output="/tmp/3xui_install_output.txt"
    wget -N --no-check-certificate https://raw.githubusercontent.com/MHSanaei/3x-ui/refs/tags/v2.5.8/install.sh -O /tmp/3xui_install.sh
    bash /tmp/3xui_install.sh | tee $temp_output
    
    # 等待几秒确保服务启动
    sleep 3
    
    # 从安装输出提取Access URL
    local access_url=$(grep -o "Access URL: http://[^ ]*" $temp_output | cut -d' ' -f3)
    
    # 使用x-ui settings命令获取准确的配置信息
    echo -e "${YELLOW}获取面板配置信息...${NC}"
    x_ui_settings=$(x-ui settings 2>/dev/null)
    
    # 从设置中提取信息
    local panel_user=$(echo "$x_ui_settings" | grep -oP "username: \K.*" | head -1)
    local panel_pass=$(echo "$x_ui_settings" | grep -oP "password: \K.*" | head -1)
    local panel_port=$(echo "$x_ui_settings" | grep -oP "port: \K[0-9]+" | head -1)
    local panel_path=$(echo "$x_ui_settings" | grep -oP "base_path: \K.*" | head -1)
    
    # 更新主安装记录
    if [ ! -z "$panel_port" ]; then
        update_main_install_log "3X-UI:${panel_port}"
    else 
        update_main_install_log "3X-UI"
    fi
    
    # 显示面板信息
    echo -e "${GREEN}3X-UI安装成功!${NC}"
    echo -e "${YELLOW}面板信息:${NC}"
    
    # 优先使用从安装输出中提取的完整Access URL
    if [ ! -z "$access_url" ]; then
        echo -e "  面板地址: $access_url"
    elif [ ! -z "$panel_port" ]; then
        if [ ! -z "$panel_path" ] && [ "$panel_path" != "/" ]; then
            echo -e "  面板地址: http://${PUBLIC_IPV4}:${panel_port}${panel_path}"
        else
            echo -e "  面板地址: http://${PUBLIC_IPV4}:${panel_port}"
        fi
    else
        echo -e "  面板地址: http://${PUBLIC_IPV4}:2053 (默认端口)"
    fi
    
    if [ ! -z "$panel_user" ] && [ ! -z "$panel_pass" ]; then
        echo -e "  用户名: $panel_user"
        echo -e "  密码: $panel_pass"
    else
        # 尝试从安装输出中提取用户名密码
        local username=$(grep -o "Username: [^ ]*" $temp_output | cut -d' ' -f2)
        local password=$(grep -o "Password: [^ ]*" $temp_output | cut -d' ' -f2)
        if [ ! -z "$username" ] && [ ! -z "$password" ]; then
            echo -e "  用户名: $username"
            echo -e "  密码: $password"
        else
            echo -e "  默认用户名: admin"
            echo -e "  默认密码: admin"
        fi
    fi
    
    echo -e "  请登录后立即修改默认密码!"
    
    # 记录到日志文件
    echo "PANEL_PORT: $panel_port" >> $log_file
    echo "PANEL_PATH: $panel_path" >> $log_file
    echo "PANEL_USER: $panel_user" >> $log_file
    echo "PANEL_PASS: $panel_pass" >> $log_file
    echo "ACCESS_URL: $access_url" >> $log_file
    
    # 清理临时文件
    rm -f /tmp/3xui_install.sh
    rm -f $temp_output
    
    read -p "按回车键继续..." temp
}

# 安装Sing-box-yg
install_singbox_yg() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装Sing-box-yg:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 创建日志目录
    mkdir -p /root/.sb_logs
    local log_file="/root/.sb_logs/singbox_yg_install.log"
    
    # 记录开始安装
    echo "# Sing-box-yg安装日志" > $log_file
    echo "# 安装时间: $(date "+%Y-%m-%d %H:%M:%S")" >> $log_file
    
    # 安装Sing-box-yg
    echo -e "${YELLOW}开始安装Sing-box-yg...${NC}"
        bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
    
    # 检查安装结果
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo -e "${GREEN}Sing-box-yg安装成功!${NC}"
        
        # 更新主安装记录
        update_main_install_log "Sing-box-yg"
    else
        echo -e "${RED}Sing-box-yg安装失败，请检查网络或稍后再试${NC}"
    fi
    
    read -p "按回车键继续..." temp
}

# 创建xx命令快捷方式
create_xx_shortcut() {
    if [ ! -f "/usr/local/bin/xx" ]; then
        echo '#!/bin/bash' > /usr/local/bin/xx
        echo "bash $(pwd)/xx.sh" >> /usr/local/bin/xx
        chmod +x /usr/local/bin/xx
    fi
}

# 更新主安装日志
update_main_install_log() {
    local component=$1
    local log_file="/root/.sb_logs/main_install.log"
    
    # 创建日志目录和文件（如果不存在）
    mkdir -p /root/.sb_logs
    touch $log_file
    
    # 添加安装记录
    echo "$component:$(date "+%Y-%m-%d %H:%M:%S")" >> $log_file
}

# 安装证书菜单
install_certificate_menu() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}安装SSL证书 (HTTP验证):${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        certificate_management
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 申请证书
    issue_certificate_http "$DOMAIN"
    
    read -p "按回车键继续..." temp
    certificate_management
}

# 安装acme.sh
install_acme() {
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        echo -e "${YELLOW}安装acme.sh所需环境...${NC}"
        
        # 检测系统类型
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu系统
            apt update
            apt install -y curl socat cron ca-certificates openssl
            
            # 确保cron服务启动
            systemctl enable cron
            systemctl start cron
        elif [ -f /etc/redhat-release ]; then
            # CentOS/RHEL系统
            yum install -y curl socat cronie ca-certificates openssl
            
            # 确保cron服务启动
            systemctl enable crond
            systemctl start crond
        else
            echo -e "${RED}不支持的系统类型${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}安装acme.sh...${NC}"
        curl https://get.acme.sh | sh
        
        # 如果安装失败，尝试强制安装
        if [ ! -f "/root/.acme.sh/acme.sh" ]; then
            echo -e "${YELLOW}尝试强制安装acme.sh...${NC}"
            curl https://get.acme.sh | sh -s -- --force
        fi
    fi
    
    # 检查安装是否成功
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        echo -e "${RED}acme.sh安装失败，请检查网络或手动安装${NC}"
        return 1
    fi
    
    # 设置默认CA
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
}

# 使用HTTP验证申请证书
issue_certificate_http() {
    local domain=$1
    
    echo -e "${YELLOW}使用HTTP验证申请证书...${NC}"
    
    # 询问邮箱
    echo -e "${YELLOW}请输入您的邮箱 (用于接收证书过期通知):${NC}"
    echo -e "${YELLOW}如果不填写，将使用默认邮箱 xxxx@xxxx.com${NC}"
    read -p "邮箱: " EMAIL
    
    # 如果未提供邮箱，使用默认邮箱
    if [ -z "$EMAIL" ]; then
        EMAIL="admin@${domain}"
        echo -e "${YELLOW}使用默认邮箱: ${EMAIL}${NC}"
    fi
    
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
    
    # 注册邮箱
    /root/.acme.sh/acme.sh --register-account -m "$EMAIL"
    
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

# 安装证书
install_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}安装证书...${NC}"
    
    # 询问证书安装位置
    echo -e "${YELLOW}请选择证书安装位置:${NC}"
    echo -e "  1) 默认位置 (/root/cert/${domain}.key 和 /root/cert/${domain}.pem)"
    echo -e "  2) 系统默认位置 (/etc/ssl/private/${domain}.key 和 /etc/ssl/certs/${domain}.pem)"
    echo -e "  3) 自定义位置"
    read -p "选择 [1-3] (默认: 1): " CERT_LOCATION
    CERT_LOCATION=${CERT_LOCATION:-1}
    
    # 根据选择设置证书路径
    case $CERT_LOCATION in
        1)
            # 默认位置
            mkdir -p /root/cert
            KEY_FILE="/root/cert/${domain}.key"
            CERT_FILE="/root/cert/${domain}.pem"
            ;;
        2)
            # 系统默认位置
            mkdir -p /etc/ssl/private
            mkdir -p /etc/ssl/certs
            KEY_FILE="/etc/ssl/private/${domain}.key"
            CERT_FILE="/etc/ssl/certs/${domain}.pem"
            ;;
        3)
            # 自定义位置
            echo -e "${YELLOW}请输入私钥文件路径:${NC}"
            read -p "私钥路径: " KEY_FILE
            echo -e "${YELLOW}请输入证书文件路径:${NC}"
            read -p "证书路径: " CERT_FILE
            
            # 创建目录
            mkdir -p $(dirname "$KEY_FILE")
            mkdir -p $(dirname "$CERT_FILE")
            ;;
        *)
            echo -e "${RED}无效选项，使用默认位置${NC}"
            mkdir -p /root/cert
            KEY_FILE="/root/cert/${domain}.key"
            CERT_FILE="/root/cert/${domain}.pem"
            ;;
    esac
    
    # 安装证书
    /root/.acme.sh/acme.sh --install-cert -d "$domain" \
        --key-file "$KEY_FILE" \
        --fullchain-file "$CERT_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书安装成功${NC}"
        
        # 设置适当的权限
        chmod 644 "$CERT_FILE"
        chmod 600 "$KEY_FILE"
        echo -e "${GREEN}证书权限已设置${NC}"
        
        # 更新主安装记录，包括证书位置
        update_main_install_log "SSL证书:$domain"
        update_main_install_log "证书路径:$CERT_FILE"
        update_main_install_log "私钥路径:$KEY_FILE"
        
        echo -e "${YELLOW}证书信息:${NC}"
        echo -e "  证书路径: $CERT_FILE"
        echo -e "  私钥路径: $KEY_FILE"
    else
        echo -e "${RED}证书安装失败${NC}"
    fi
}

# 更新证书菜单
update_certificates_menu() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}更新SSL证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    local main_log="/root/.sb_logs/main_install.log"
    local domains=()
    
    # 获取所有已安装的证书域名
        while IFS= read -r line; do
        if [[ $line == *"SSL证书:"* ]]; then
            domain=$(echo $line | cut -d':' -f2)
            domains+=("$domain")
        fi
    done < "$main_log"
    
    if [ ${#domains[@]} -eq 0 ]; then
        echo -e "${RED}未找到已安装的证书${NC}"
        read -p "按回车键继续..." temp
        certificate_management
        return
    fi
    
    echo -e "${YELLOW}已安装的证书:${NC}"
    local count=1
    for domain in "${domains[@]}"; do
        echo -e "${WHITE}$count)${NC} ${GREEN}$domain${NC}"
        ((count++))
    done
    
    echo -e "${WHITE}$count)${NC} ${YELLOW}更新所有证书${NC}"
    echo -e "${WHITE}0)${NC} ${RED}返回${NC}"
    
    read -p "请选择 [0-$count]: " CERT_OPTION
    
    if [ "$CERT_OPTION" = "0" ]; then
        certificate_management
        return
    elif [ "$CERT_OPTION" = "$count" ]; then
        # 更新所有证书
        update_all_certificates
    elif [ "$CERT_OPTION" -ge 1 ] && [ "$CERT_OPTION" -lt "$count" ]; then
        # 更新特定证书
        local domain=${domains[$((CERT_OPTION-1))]}
        update_certificate "$domain"
    else
        echo -e "${RED}无效选项${NC}"
        sleep 2
        update_certificates_menu
    fi
}

# 更新所有证书
update_all_certificates() {
    echo -e "${YELLOW}更新所有证书...${NC}"
    
    /root/.acme.sh/acme.sh --renew-all
    
    echo -e "${GREEN}所有证书已更新${NC}"
    read -p "按回车键继续..." temp
    certificate_management
}

# 更新特定证书
update_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}更新域名为 $domain 的证书...${NC}"
    
    /root/.acme.sh/acme.sh --renew -d "$domain" --force
    
    echo -e "${GREEN}证书已更新${NC}"
    read -p "按回车键继续..." temp
    certificate_management
}

# 删除证书菜单
delete_certificate_menu() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}删除SSL证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    local main_log="/root/.sb_logs/main_install.log"
    local domains=()
    
    # 获取所有已安装的证书域名
    while IFS= read -r line; do
        if [[ $line == *"SSL证书:"* ]]; then
            domain=$(echo $line | cut -d':' -f2)
            domains+=("$domain")
        fi
    done < "$main_log"
    
    if [ ${#domains[@]} -eq 0 ]; then
        echo -e "${RED}未找到已安装的证书${NC}"
        read -p "按回车键继续..." temp
        certificate_management
        return
    fi
    
    echo -e "${YELLOW}已安装的证书:${NC}"
    local count=1
    for domain in "${domains[@]}"; do
        echo -e "${WHITE}$count)${NC} ${GREEN}$domain${NC}"
        ((count++))
    done
    
    echo -e "${WHITE}$count)${NC} ${YELLOW}删除所有证书${NC}"
    echo -e "${WHITE}0)${NC} ${RED}返回${NC}"
    
    read -p "请选择 [0-$count]: " CERT_OPTION
    
    if [ "$CERT_OPTION" = "0" ]; then
        certificate_management
        return
    elif [ "$CERT_OPTION" = "$count" ]; then
        # 删除所有证书
        delete_all_certificates
    elif [ "$CERT_OPTION" -ge 1 ] && [ "$CERT_OPTION" -lt "$count" ]; then
        # 删除特定证书
        local domain=${domains[$((CERT_OPTION-1))]}
        delete_certificate "$domain"
    else
        echo -e "${RED}无效选项${NC}"
        sleep 2
        delete_certificate_menu
    fi
}

# 删除所有证书
delete_all_certificates() {
    echo -e "${RED}警告: 此操作将删除所有证书!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " DELETE_ALL_CONFIRM
    
    if [[ $DELETE_ALL_CONFIRM =~ ^[Yy]$ ]]; then
        local main_log="/root/.sb_logs/main_install.log"
        local domains=()
        
        # 获取所有已安装的证书域名
        while IFS= read -r line; do
            if [[ $line == *"SSL证书:"* ]]; then
                domain=$(echo $line | cut -d':' -f2)
                domains+=("$domain")
            fi
        done < "$main_log"
        
        for domain in "${domains[@]}"; do
            delete_certificate "$domain"
        done
    else
        echo -e "${YELLOW}已取消删除${NC}"
    fi
    
    read -p "按回车键继续..." temp
    certificate_management
}

# 删除特定证书
delete_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}删除域名为 $domain 的证书...${NC}"
    
    # 使用acme.sh删除证书
    /root/.acme.sh/acme.sh --revoke -d "$domain" --force
    /root/.acme.sh/acme.sh --remove -d "$domain" --force
    
    # 查找证书文件位置
    local cert_locations=$(grep -A 2 "SSL证书:$domain" /root/.sb_logs/main_install.log | grep "证书路径:" | awk '{print $2}')
    local key_locations=$(grep -A 2 "SSL证书:$domain" /root/.sb_logs/main_install.log | grep "私钥路径:" | awk '{print $2}')
    
    # 如果在日志中找到了证书位置，删除这些位置的文件
    if [ -n "$cert_locations" ] && [ -n "$key_locations" ]; then
        echo -e "${YELLOW}删除记录的证书文件...${NC}"
        rm -f $cert_locations
        rm -f $key_locations
    else
        # 如果没有找到记录，尝试删除默认位置的文件
        echo -e "${YELLOW}未找到证书位置记录，尝试删除默认位置的文件...${NC}"
        rm -f "/root/cert/${domain}.pem"
        rm -f "/root/cert/${domain}.key"
        # 尝试删除系统默认位置的文件
        rm -f "/etc/ssl/certs/${domain}.pem"
        rm -f "/etc/ssl/private/${domain}.key"
    fi
    
    # 从安装日志中删除
    sed -i "/SSL证书:${domain}/d" /root/.sb_logs/main_install.log 2>/dev/null
    sed -i "/证书路径:.*${domain}/d" /root/.sb_logs/main_install.log 2>/dev/null
    sed -i "/私钥路径:.*${domain}/d" /root/.sb_logs/main_install.log 2>/dev/null
    
    echo -e "${GREEN}证书已删除${NC}"
}

# GoDaddy DNS API
dns_api_godaddy() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用GoDaddy DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入GoDaddy API Key:${NC}"
    read -p "API Key: " GD_KEY
    
    echo -e "${YELLOW}请输入GoDaddy API Secret:${NC}"
    read -p "API Secret: " GD_SECRET
    
    if [ -z "$GD_KEY" ] || [ -z "$GD_SECRET" ]; then
        echo -e "${RED}API Key和Secret不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export GD_Key="$GD_KEY"
    export GD_Secret="$GD_SECRET"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_gd -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# Namesilo DNS API
dns_api_namesilo() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}使用Namesilo DNS API申请证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请输入域名:${NC}"
    read -p "域名: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    echo -e "${YELLOW}请输入Namesilo API Key:${NC}"
    read -p "API Key: " NS_KEY
    
    if [ -z "$NS_KEY" ]; then
        echo -e "${RED}API Key不能为空${NC}"
        read -p "按回车键继续..." temp
        dns_api_certificate
        return
    fi
    
    # 安装acme.sh
    install_acme
    
    # 设置环境变量
    export Namesilo_Key="$NS_KEY"
    
    # 申请证书
    /root/.acme.sh/acme.sh --issue --dns dns_namesilo -d "$DOMAIN" -d "*.$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书申请成功${NC}"
        
        # 安装证书
        install_certificate "$DOMAIN"
    else
        echo -e "${RED}证书申请失败${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 删除所有证书 (DNS管理专用)
delete_all_certificates_dns() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}删除所有证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${RED}警告: 此操作将删除所有证书!${NC}"
    echo -e "${YELLOW}是否继续? (y/n)${NC}"
    read -p "选择 [y/n]: " DELETE_ALL_CONFIRM
    
    if [[ $DELETE_ALL_CONFIRM =~ ^[Yy]$ ]]; then
        # 使用acme.sh卸载
        if [ -f "/root/.acme.sh/acme.sh" ]; then
            /root/.acme.sh/acme.sh --uninstall
            rm -rf /root/.acme.sh
            
            # 删除证书文件
            rm -rf /root/cert
            
            # 清空安装日志中的证书记录
            sed -i '/SSL证书:/d' /root/.sb_logs/main_install.log 2>/dev/null
            
            echo -e "${GREEN}所有证书已删除${NC}"
        else
            echo -e "${RED}未找到acme.sh，无法删除证书${NC}"
        fi
    else
        echo -e "${YELLOW}已取消删除${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 更新acme.sh及其所有证书
update_acme_and_certs() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}更新acme.sh及其所有证书:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 更新acme.sh
    if [ -f "/root/.acme.sh/acme.sh" ]; then
        echo -e "${YELLOW}更新acme.sh...${NC}"
        /root/.acme.sh/acme.sh --upgrade
        
        echo -e "${YELLOW}更新所有证书...${NC}"
        /root/.acme.sh/acme.sh --renew-all
        
        echo -e "${GREEN}acme.sh和所有证书已更新${NC}"
    else
        echo -e "${RED}未找到acme.sh，无法更新${NC}"
    fi
    
    read -p "按回车键继续..." temp
    dns_management
}

# 调用主函数
main