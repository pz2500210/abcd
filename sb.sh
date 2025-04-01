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

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}           服务器管理面板 v1.0                  ${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}系统信息:${NC}"
    echo -e "  主机名: $(hostname)"
    echo -e "  系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  内核版本: $(uname -r)"
    echo -e "  架构: $(uname -m)"
    
    # 获取本地IP地址
    LOCAL_IPV4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -1)
    LOCAL_IPV6=$(ip -6 addr show | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "::1" | grep -v "fe80" | head -1)
    
    # 尝试获取公网IP地址（使用多个服务以提高可靠性）
    PUBLIC_IPV4=$(curl -s -m 2 -4 https://api.ipify.org 2>/dev/null || curl -s -m 2 -4 https://ipinfo.io/ip 2>/dev/null || curl -s -m 2 -4 https://ifconfig.me 2>/dev/null)
    PUBLIC_IPV6=$(curl -s -m 2 -6 https://api6.ipify.org 2>/dev/null || curl -s -m 2 -6 https://ifconfig.co 2>/dev/null)
    
    # 如果公网IP获取失败，使用本地IP
    if [ -z "$PUBLIC_IPV4" ]; then
        PUBLIC_IPV4=$LOCAL_IPV4
    fi
    
    # 显示IP地址信息
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
    echo -e "${CYAN}请选择操作:${NC}"
    echo -e "${WHITE}1)${NC} ${GREEN}初始化服务器${NC} - 安装基础环境和工具"
    echo -e "${WHITE}2)${NC} ${YELLOW}重新安装${NC} - 清理并重新安装"
    echo -e "${WHITE}3)${NC} ${RED}卸载${NC} - 删除所有安装的组件"
    echo -e "${WHITE}4)${NC} ${BLUE}查看配置信息${NC} - 显示详细配置"
    echo -e "${WHITE}5)${NC} ${PURPLE}系统工具${NC} - 实用工具集"
    echo -e "${WHITE}0)${NC} ${RED}退出${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

# 初始化服务器
initialize_server() {
    echo -e "${GREEN}开始初始化服务器...${NC}"
    if [ -f "/root/server_init.sh" ]; then
        bash /root/server_init.sh
    else
        echo -e "${YELLOW}下载初始化脚本...${NC}"
        curl -o /root/server_init.sh https://raw.githubusercontent.com/yourusername/server-scripts/main/server_init.sh
        chmod +x /root/server_init.sh
        bash /root/server_init.sh
    fi
}

# 重新安装
reinstall() {
    echo -e "${YELLOW}重新安装将先清理现有安装，然后重新初始化服务器${NC}"
    read -p "是否继续? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "/root/cleanup.sh" ]; then
            bash /root/cleanup.sh
        else
            echo -e "${YELLOW}下载清理脚本...${NC}"
            curl -o /root/cleanup.sh https://raw.githubusercontent.com/yourusername/server-scripts/main/cleanup.sh
            chmod +x /root/cleanup.sh
            bash /root/cleanup.sh
        fi
        
        # 清理完成后重新初始化
        initialize_server
    fi
}

# 卸载
uninstall() {
    echo -e "${RED}卸载将删除所有已安装的组件${NC}"
    read -p "是否继续? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "/root/cleanup.sh" ]; then
            bash /root/cleanup.sh
        else
            echo -e "${YELLOW}下载清理脚本...${NC}"
            curl -o /root/cleanup.sh https://raw.githubusercontent.com/yourusername/server-scripts/main/cleanup.sh
            chmod +x /root/cleanup.sh
            bash /root/cleanup.sh
        fi
    fi
}

# 查看配置信息
show_config() {
    clear
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}服务器配置信息:${NC}"
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${YELLOW}系统信息:${NC}"
    echo -e "  主机名: $(hostname)"
    echo -e "  系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  内核版本: $(uname -r)"
    echo -e "  架构: $(uname -m)"
    
    # 获取本地IP地址
    LOCAL_IPV4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -1)
    LOCAL_IPV6=$(ip -6 addr show | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v "::1" | grep -v "fe80" | head -1)
    
    # 尝试获取公网IP地址（使用多个服务以提高可靠性）
    PUBLIC_IPV4=$(curl -s -m 2 -4 https://api.ipify.org 2>/dev/null || curl -s -m 2 -4 https://ipinfo.io/ip 2>/dev/null || curl -s -m 2 -4 https://ifconfig.me 2>/dev/null)
    PUBLIC_IPV6=$(curl -s -m 2 -6 https://api6.ipify.org 2>/dev/null || curl -s -m 2 -6 https://ifconfig.co 2>/dev/null)
    
    # 如果公网IP获取失败，使用本地IP
    if [ -z "$PUBLIC_IPV4" ]; then
        PUBLIC_IPV4=$LOCAL_IPV4
    fi
    
    # 显示IP地址信息
    echo -e "  IP地址: ${PUBLIC_IPV4}"
    if [ ! -z "$PUBLIC_IPV6" ]; then
        echo -e "  IPv6地址: ${PUBLIC_IPV6}"
    elif [ ! -z "$LOCAL_IPV6" ]; then
        echo -e "  IPv6地址: ${LOCAL_IPV6}"
    fi
    echo -e "  内网IP: ${LOCAL_IPV4}"
    echo -e "  时区: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    
    # 其他配置信息...
    echo -e "${YELLOW}性能信息:${NC}"
    echo -e "  CPU: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | xargs)"
    echo -e "  CPU核心数: $(nproc)"
    echo -e "  内存总量: $(free -h | grep Mem | awk '{print $2}')"
    echo -e "  可用内存: $(free -h | grep Mem | awk '{print $7}')"
    
    echo -e "${YELLOW}磁盘使用情况:${NC}"
    df -h | grep -v tmpfs | grep -v udev
    
    echo -e "${YELLOW}网络配置:${NC}"
    echo -e "  BBR状态: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo -e "  开放端口:"
    netstat -tuln | grep LISTEN
    
    echo -e "${YELLOW}证书信息:${NC}"
    if [ -d "/etc/letsencrypt/live" ]; then
        echo -e "  已安装证书:"
        ls -1 /etc/letsencrypt/live
    else
        echo -e "  未找到证书"
    fi
    
    echo -e "${YELLOW}服务状态:${NC}"
    echo -e "  SSH: $(systemctl is-active sshd)"
    echo -e "  Cron: $(systemctl is-active cron)"
    echo -e "  Firewall: $(systemctl is-active ufw || echo 'inactive')"
    
    # 检查其他常见服务
    for service in nginx apache2 mysql docker; do
        if systemctl list-unit-files | grep -q $service; then
            echo -e "  $service: $(systemctl is-active $service)"
        fi
    done
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${CYAN}按任意键返回主菜单...${NC}"
    read -n 1
}

# 系统工具菜单
system_tools() {
    while true; do
        show_banner
        echo -e "${PURPLE}系统工具:${NC}"
        echo -e "${WHITE}1)${NC} ${GREEN}查看系统状态${NC} - CPU/内存/磁盘使用情况"
        echo -e "${WHITE}2)${NC} ${GREEN}网络测速${NC} - 测试网络速度"
        echo -e "${WHITE}3)${NC} ${GREEN}防火墙管理${NC} - 配置防火墙规则"
        echo -e "${WHITE}4)${NC} ${GREEN}证书管理${NC} - 更新/查看证书"
        echo -e "${WHITE}5)${NC} ${GREEN}系统更新${NC} - 更新系统包"
        echo -e "${WHITE}0)${NC} ${RED}返回主菜单${NC}"
        echo -e "${BLUE}=================================================${NC}"
        
        read -p "请选择 [0-5]: " TOOL_OPTION
        
        case $TOOL_OPTION in
            1) # 系统状态
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}系统状态:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${YELLOW}CPU使用情况:${NC}"
                top -bn1 | head -n 5
                echo -e "\n${YELLOW}内存使用情况:${NC}"
                free -h
                echo -e "\n${YELLOW}磁盘使用情况:${NC}"
                df -h
                echo -e "${BLUE}=================================================${NC}"
                read -p "按回车键继续..." temp
                ;;
            2) # 网络测速
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}网络测速:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
                if ! command -v speedtest-cli &> /dev/null; then
                    echo -e "${YELLOW}安装speedtest-cli...${NC}"
                    apt update && apt install -y python3-pip
                    pip3 install speedtest-cli
                fi
                
                echo -e "${YELLOW}开始测速，请稍候...${NC}"
                speedtest-cli
                
                echo -e "${BLUE}=================================================${NC}"
                read -p "按回车键继续..." temp
                ;;
            3) # 防火墙管理
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}防火墙管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
                if ! command -v ufw &> /dev/null; then
                    echo -e "${YELLOW}安装UFW防火墙...${NC}"
                    apt update && apt install -y ufw
                fi
                
                echo -e "${YELLOW}当前防火墙状态:${NC}"
                ufw status
                
                echo -e "\n${YELLOW}防火墙操作:${NC}"
                echo -e "1) 启用防火墙"
                echo -e "2) 禁用防火墙"
                echo -e "3) 开放端口"
                echo -e "4) 关闭端口"
                echo -e "0) 返回"
                
                read -p "请选择 [0-4]: " FW_OPTION
                
                case $FW_OPTION in
                    1) # 启用防火墙
                        echo "y" | ufw enable
                        echo -e "${GREEN}防火墙已启用${NC}"
                        ;;
                    2) # 禁用防火墙
                        ufw disable
                        echo -e "${YELLOW}防火墙已禁用${NC}"
                        ;;
                    3) # 开放端口
                        read -p "请输入要开放的端口: " PORT
                        ufw allow $PORT
                        echo -e "${GREEN}端口 $PORT 已开放${NC}"
                        ;;
                    4) # 关闭端口
                        read -p "请输入要关闭的端口: " PORT
                        ufw delete allow $PORT
                        echo -e "${YELLOW}端口 $PORT 已关闭${NC}"
                        ;;
                    0|*) # 返回
                        ;;
                esac
                
                read -p "按回车键继续..." temp
                ;;
            4) # 证书管理
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}证书管理:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
                if [ -d ~/.acme.sh ]; then
                    echo -e "${YELLOW}证书操作:${NC}"
                    echo -e "1) 查看证书信息"
                    echo -e "2) 更新证书"
                    echo -e "0) 返回"
                    
                    read -p "请选择 [0-2]: " CERT_OPTION
                    
                    case $CERT_OPTION in
                        1) # 查看证书信息
                            if [ -f "/root/cert.crt" ]; then
                                echo -e "${YELLOW}证书信息:${NC}"
                                openssl x509 -text -noout -in /root/cert.crt | head -20
                            elif [ -f "/etc/ssl/certs/cert.crt" ]; then
                                echo -e "${YELLOW}证书信息:${NC}"
                                openssl x509 -text -noout -in /etc/ssl/certs/cert.crt | head -20
                            else
                                echo -e "${RED}未找到证书文件${NC}"
                            fi
                            ;;
                        2) # 更新证书
                            echo -e "${YELLOW}更新所有证书...${NC}"
                            ~/.acme.sh/acme.sh --renew-all
                            echo -e "${GREEN}证书更新完成${NC}"
                            ;;
                        0|*) # 返回
                            ;;
                    esac
                else
                    echo -e "${RED}未安装acme.sh，无法管理证书${NC}"
                fi
                
                read -p "按回车键继续..." temp
                ;;
            5) # 系统更新
                clear
                echo -e "${BLUE}=================================================${NC}"
                echo -e "${GREEN}系统更新:${NC}"
                echo -e "${BLUE}=================================================${NC}"
                
                echo -e "${YELLOW}更新系统包...${NC}"
                apt update && apt upgrade -y
                
                echo -e "${GREEN}系统更新完成${NC}"
                read -p "按回车键继续..." temp
                ;;
            0) # 返回主菜单
                return
                ;;
            *)
                echo -e "${RED}无效选项${NC}"
                sleep 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 检查是否为root用户
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}此脚本必须以root用户身份运行${NC}"
        exit 1
    fi
    
    while true; do
        show_banner
        show_main_menu
        
        read -p "请选择 [0-5]: " OPTION
        
        case $OPTION in
            1) # 初始化服务器
                initialize_server
                ;;
            2) # 重新安装
                reinstall
                ;;
            3) # 卸载
                uninstall
                ;;
            4) # 查看配置信息
                show_config
                ;;
            5) # 系统工具
                system_tools
                ;;
            0) # 退出
                echo -e "${GREEN}感谢使用服务器管理面板，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 执行主函数
main 