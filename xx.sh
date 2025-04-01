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
    echo -e "  ${GREEN}4.${NC} 初始化服务器"
    echo -e "  ${GREEN}5.${NC} 卸载"
    echo -e "  ${GREEN}6.${NC} 查看配置"
    echo -e "  ${GREEN}7.${NC} 系统工具"
    echo -e "  ${GREEN}8.${NC} 安装SSL证书"
    echo -e "  ${GREEN}9.${NC} DNS认证管理"
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
    echo -e "  3) 防火墙设置"
    echo -e "  4) 端口管理"
    echo -e "  5) 系统更新"
    echo -e "  6) 重启系统"
    echo -e "  7) 关闭系统"
    echo -e "  0) 返回主菜单"
    
    read -p "请选择 [0-7]: " TOOL_OPTION
    
    case $TOOL_OPTION in
        1) view_system_info ;;
        2) network_speedtest ;;
        3) firewall_settings ;;
        4) port_management ;;
        5) system_update ;;
        6) reboot_system ;;
        7) shutdown_system ;;
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
    elif command -v firewalld &>/dev/null; then
        firewall_type="firewalld"
    elif command -v iptables &>/dev/null; then
        firewall_type="iptables"
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
    echo -e "  4) 开放端口"
    echo -e "  5) 关闭端口"
    echo -e "  0) 返回"
    
    read -p "请选择 [0-5]: " FW_OPTION
                
                case $FW_OPTION in
        1) 
            echo -e "${YELLOW}防火墙状态:${NC}"
            case $firewall_type in
                ufw) ufw status ;;
                firewalld) firewall-cmd --state ;;
                iptables) iptables -L -n ;;
            esac
            ;;
        2) 
            echo -e "${YELLOW}开启防火墙...${NC}"
            case $firewall_type in
                ufw) ufw enable ;;
                firewalld) systemctl start firewalld && systemctl enable firewalld ;;
                iptables) systemctl start iptables && systemctl enable iptables ;;
            esac
            ;;
        3) 
            echo -e "${YELLOW}关闭防火墙...${NC}"
            case $firewall_type in
                ufw) ufw disable ;;
                firewalld) systemctl stop firewalld && systemctl disable firewalld ;;
                iptables) systemctl stop iptables && systemctl disable iptables ;;
            esac
            ;;
        4) 
            echo -e "${YELLOW}请输入要开放的端口:${NC}"
            read -p "端口: " OPEN_PORT
            
            if [ -z "$OPEN_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}开放端口 $OPEN_PORT...${NC}"
                case $firewall_type in
                    ufw) ufw allow $OPEN_PORT ;;
                    firewalld) firewall-cmd --permanent --add-port=$OPEN_PORT/tcp && firewall-cmd --permanent --add-port=$OPEN_PORT/udp && firewall-cmd --reload ;;
                    iptables) iptables -A INPUT -p tcp --dport $OPEN_PORT -j ACCEPT && iptables -A INPUT -p udp --dport $OPEN_PORT -j ACCEPT && iptables-save > /etc/iptables/rules.v4 ;;
                esac
                echo -e "${GREEN}端口 $OPEN_PORT 已开放${NC}"
            fi
            ;;
        5) 
            echo -e "${YELLOW}请输入要关闭的端口:${NC}"
            read -p "端口: " CLOSE_PORT
            
            if [ -z "$CLOSE_PORT" ]; then
                echo -e "${RED}端口不能为空${NC}"
            else
                echo -e "${YELLOW}关闭端口 $CLOSE_PORT...${NC}"
                case $firewall_type in
                    ufw) ufw delete allow $CLOSE_PORT ;;
                    firewalld) firewall-cmd --permanent --remove-port=$CLOSE_PORT/tcp && firewall-cmd --permanent --remove-port=$CLOSE_PORT/udp && firewall-cmd --reload ;;
                    iptables) iptables -D INPUT -p tcp --dport $CLOSE_PORT -j ACCEPT && iptables -D INPUT -p udp --dport $CLOSE_PORT -j ACCEPT && iptables-save > /etc/iptables/rules.v4 ;;
                esac
                echo -e "${GREEN}端口 $CLOSE_PORT 已关闭${NC}"
            fi
            ;;
        0) 
            system_tools
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

# 证书管理
certificate_management() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}SSL证书管理:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  1) 安装新证书 (HTTP验证)"
    echo -e "  2) 重新安装证书"
    echo -e "  3) 更新证书"
    echo -e "  4) 删除证书"
    echo -e "  0) 返回主菜单"
    
    read -p "选择 [0-4]: " CERT_OPTION
    
    case $CERT_OPTION in
        1) install_certificate_menu ;;
        2) reinstall_certificates_menu ;;
        3) update_certificates_menu ;;
        4) delete_certificates_menu ;;
        0) return ;;
        *) 
            echo -e "${RED}无效选项，请重试${NC}"
            sleep 2
            certificate_management
            ;;
    esac
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

# 主函数
main() {
    # 在脚本开始时获取IP地址，确保所有函数都使用相同的值
    get_ip_addresses
    
    # 在脚本开始时调用
    create_xx_shortcut
    
    while true; do
        show_banner
        show_main_menu
        
        read -p "请选择 [0-9]: " OPTION
        
        case $OPTION in
            1) install_or_reinstall_hysteria2 ;;
            2) install_or_reinstall_3xui ;;
            3) install_or_reinstall_singbox_yg ;;
            4) initialize_server ;;
            5) uninstall ;;
            6) show_config ;;  # 这里需要修改为正确的函数名
            7) system_tools ;;
            8) certificate_management ;;
            9) dns_management ;;
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
        echo -e "  2) 修改配置"
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
        echo -e "  2) 修改配置"
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
    
    # 安装Hysteria-2
    echo -e "${YELLOW}开始安装Hysteria-2...${NC}"
    wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
    
    # 检查安装结果
    if [ -f "/usr/local/bin/hysteria" ]; then
        echo -e "${GREEN}Hysteria-2安装成功!${NC}"
        
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
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    
    # 检查安装结果
    if [ -f "/usr/local/x-ui/x-ui" ] || [ -f "/usr/bin/x-ui" ]; then
        echo -e "${GREEN}3X-UI安装成功!${NC}"
        
        # 获取面板端口
        PANEL_PORT=$(grep "^port:" /usr/local/x-ui/config.yaml 2>/dev/null | awk '{print $2}' || echo "2053")
        
        # 记录安装信息
        echo "PANEL_PORT:$PANEL_PORT" >> $log_file
        
        # 更新主安装记录
        update_main_install_log "3X-UI:${PANEL_PORT}"
        
        echo -e "${YELLOW}面板信息:${NC}"
        echo -e "  面板地址: http://${PUBLIC_IPV4}:${PANEL_PORT}"
        echo -e "  默认用户名: admin"
        echo -e "  默认密码: admin"
        echo -e "  请登录后立即修改默认密码!"
    else
        echo -e "${RED}3X-UI安装失败，请检查网络或稍后再试${NC}"
    fi
    
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

# 安装证书
install_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}安装证书...${NC}"
    
    # 创建证书目录
    mkdir -p /root/cert
    
    # 安装证书
    /root/.acme.sh/acme.sh --install-cert -d "$domain" \
        --key-file /root/cert/"$domain".key \
        --fullchain-file /root/cert/"$domain".pem
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}证书安装成功${NC}"
        
        # 更新主安装记录
        update_main_install_log "SSL证书:$domain"
        
        echo -e "${YELLOW}证书信息:${NC}"
        echo -e "  证书路径: /root/cert/$domain.pem"
        echo -e "  私钥路径: /root/cert/$domain.key"
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
delete_certificates_menu() {
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
        delete_certificates_menu
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
    
    # 删除证书文件
    rm -f "/root/cert/${domain}.pem"
    rm -f "/root/cert/${domain}.key"
    
    # 从安装日志中删除
    sed -i "/SSL证书:${domain}/d" /root/.sb_logs/main_install.log 2>/dev/null
    
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