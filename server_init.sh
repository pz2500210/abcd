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
    
    # 配置日志轮转
    configure_logrotate
    
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

# 5. 安装和配置证书
install_cert() {
    echo -e "${YELLOW}[5/5] 安装和配置SSL证书...${NC}"
    
    # 询问是否申请SSL证书
    echo -e "${YELLOW}是否申请SSL证书? (Y/N)${NC}"
    read -p "选择 [Y/N]: " APPLY_CERT
    
    if [[ "$APPLY_CERT" =~ ^[Yy]$ ]]; then
        # 首先选择验证方式
        echo -e "${YELLOW}请选择验证方式:${NC}"
        echo -e "  1) HTTP 验证 (需要占用 80 端口)"
        echo -e "  2) DNS 验证 (不占用端口，支持通配符证书)"
        read -p "选择 [1-2] (默认: 1): " VALIDATION_METHOD
        VALIDATION_METHOD=${VALIDATION_METHOD:-1}
        
        # 如果选择DNS验证，选择DNS提供商
        if [ "$VALIDATION_METHOD" = "2" ]; then
            echo -e "${YELLOW}请选择您的 DNS 提供商:${NC}"
            echo -e "  1) Cloudflare"
            echo -e "  2) Aliyun (阿里云)"
            echo -e "  3) DNSPod/Tencent Cloud (腾讯云)"
            echo -e "  4) Namesilo"
            echo -e "  5) GoDaddy"
            echo -e "  6) Cloudflare API Token (推荐)"
            echo -e "  7) 手动 DNS 验证"
            echo -e "  8) 其他 DNS 提供商"
            read -p "选择 DNS 提供商 [1-8] (默认: 7): " DNS_PROVIDER
            DNS_PROVIDER=${DNS_PROVIDER:-7}
        fi
        
        # 然后选择证书提供商
        echo -e "${YELLOW}请选择证书提供商:${NC}"
        echo -e "  1) Let's Encrypt (使用acme.sh，默认)"
        echo -e "  2) ZeroSSL (使用acme.sh)"
        echo -e "  3) Buypass (使用acme.sh)"
        echo -e "  4) SSL.com (使用acme.sh)"
        echo -e "  5) 自定义已有证书"
        read -p "选择证书提供商 [1-5] (默认: 1): " CA_PROVIDER
        CA_PROVIDER=${CA_PROVIDER:-1}
        
        # 处理证书提供商选择
        case $CA_PROVIDER in
            1|2|3|4) # acme.sh支持的CA
                # 安装acme.sh
                curl https://get.acme.sh | sh
                if [ ! -f ~/.acme.sh/acme.sh ]; then
                    echo -e "${RED}acme.sh 安装失败，尝试备用方法...${NC}"
                    # 备用安装方法
                    git clone https://github.com/acmesh-official/acme.sh.git
                    cd acme.sh
                    ./acme.sh --install
                    cd ..
                    rm -rf acme.sh
                    
                    if [ ! -f ~/.acme.sh/acme.sh ]; then
                        echo -e "${RED}acme.sh 安装失败，请手动安装${NC}"
                        echo -e "${YELLOW}手动安装命令: curl https://get.acme.sh | sh${NC}"
                        exit 1
                    fi
                fi
                
                # 设置默认CA
                case $CA_PROVIDER in
                    1) # Let's Encrypt
                        CA_NAME="Let's Encrypt"
                        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                        ;;
                    2) # ZeroSSL
                        CA_NAME="ZeroSSL"
                        ~/.acme.sh/acme.sh --set-default-ca --server zerossl
                        ;;
                    3) # Buypass
                        CA_NAME="Buypass"
                        ~/.acme.sh/acme.sh --set-default-ca --server buypass
                        ;;
                    4) # SSL.com
                        CA_NAME="SSL.com"
                        ~/.acme.sh/acme.sh --set-default-ca --server ssl.com
                        ;;
                esac
                
                echo -e "${GREEN}已选择 ${CA_NAME} 作为证书提供商${NC}"
                
                # 注册账户
                echo -e "${YELLOW}请输入您的邮箱地址(用于注册${CA_NAME}账户)${NC}"
                echo -e "${YELLOW}直接回车使用默认邮箱: xxxx@xxxx.com${NC}"
                read -p "邮箱: " EMAIL
                if [ -z "$EMAIL" ]; then
                    EMAIL="xxxx@xxxx.com"
                    echo -e "${YELLOW}使用默认邮箱: $EMAIL${NC}"
                fi
                ~/.acme.sh/acme.sh --register-account -m $EMAIL
                
                # 获取域名
                echo -e "${YELLOW}请输入您的域名:${NC}"
                read -p "域名: " DOMAIN
                
                if [ -z "$DOMAIN" ]; then
                    echo -e "${RED}域名不能为空，跳过证书申请${NC}"
                else
                    # 根据之前选择的验证方式处理
                    case $VALIDATION_METHOD in
                        1) # HTTP 验证
                            echo -e "${YELLOW}使用 HTTP 验证方式...${NC}"
                            # 检查80端口是否被占用
                            if lsof -i:80 > /dev/null 2>&1; then
                                echo -e "${RED}警告: 80端口已被占用，可能会导致验证失败${NC}"
                                echo -e "${YELLOW}是否尝试临时停止占用80端口的服务? (Y/N)${NC}"
                                read -p "选择 [Y/N]: " STOP_SERVICE
                                if [[ "$STOP_SERVICE" =~ ^[Yy]$ ]]; then
                                    echo -e "${YELLOW}尝试停止服务...${NC}"
                                    service nginx stop 2>/dev/null || systemctl stop nginx 2>/dev/null
                                    service apache2 stop 2>/dev/null || systemctl stop apache2 2>/dev/null
                                    service httpd stop 2>/dev/null || systemctl stop httpd 2>/dev/null
                                fi
                            fi
                            
                            # 申请证书
                            ~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone
                            ;;
                        2) # DNS 验证
                            echo -e "${YELLOW}使用 DNS 验证方式...${NC}"
                            
                            # 根据之前选择的DNS提供商处理
                            case $DNS_PROVIDER in
                                1) # Cloudflare Global API Key
                                    echo -e "${YELLOW}请输入 Cloudflare Global API Key:${NC}"
                                    read -p "API Key: " CF_Key
                                    echo -e "${YELLOW}请输入 Cloudflare 账户邮箱:${NC}"
                                    read -p "邮箱: " CF_Email
                                    export CF_Key="$CF_Key"
                                    export CF_Email="$CF_Email"
                                    ~/.acme.sh/acme.sh --issue --dns dns_cf -d $DOMAIN
                                    ;;
                                2) # Aliyun
                                    echo -e "${YELLOW}请输入阿里云 AccessKey ID:${NC}"
                                    read -p "AccessKey ID: " Ali_Key
                                    echo -e "${YELLOW}请输入阿里云 AccessKey Secret:${NC}"
                                    read -p "AccessKey Secret: " Ali_Secret
                                    export Ali_Key="$Ali_Key"
                                    export Ali_Secret="$Ali_Secret"
                                    ~/.acme.sh/acme.sh --issue --dns dns_ali -d $DOMAIN
                                    ;;
                                3) # DNSPod
                                    echo -e "${YELLOW}请输入 DNSPod ID:${NC}"
                                    read -p "DNSPod ID: " DP_Id
                                    echo -e "${YELLOW}请输入 DNSPod Key:${NC}"
                                    read -p "DNSPod Key: " DP_Key
                                    export DP_Id="$DP_Id"
                                    export DP_Key="$DP_Key"
                                    ~/.acme.sh/acme.sh --issue --dns dns_dp -d $DOMAIN
                                    ;;
                                4) # Namesilo
                                    echo -e "${YELLOW}请输入 Namesilo API Key:${NC}"
                                    read -p "API Key: " Namesilo_Key
                                    export Namesilo_Key="$Namesilo_Key"
                                    ~/.acme.sh/acme.sh --issue --dns dns_namesilo -d $DOMAIN
                                    ;;
                                5) # GoDaddy
                                    echo -e "${YELLOW}请输入 GoDaddy API Key:${NC}"
                                    read -p "API Key: " GD_Key
                                    echo -e "${YELLOW}请输入 GoDaddy API Secret:${NC}"
                                    read -p "API Secret: " GD_Secret
                                    export GD_Key="$GD_Key"
                                    export GD_Secret="$GD_Secret"
                                    ~/.acme.sh/acme.sh --issue --dns dns_gd -d $DOMAIN
                                    ;;
                                6) # Cloudflare API Token
                                    echo -e "${YELLOW}请输入 Cloudflare API Token:${NC}"
                                    read -p "API Token: " CF_Token
                                    echo -e "${YELLOW}请输入 Cloudflare 区域 ID (Zone ID):${NC}"
                                    read -p "Zone ID: " CF_Zone_ID
                                    export CF_Token="$CF_Token"
                                    export CF_Zone_ID="$CF_Zone_ID"
                                    ~/.acme.sh/acme.sh --issue --dns dns_cf -d $DOMAIN
                                    ;;
                                7) # 手动 DNS
                                    echo -e "${YELLOW}使用手动 DNS 验证...${NC}"
                                    ~/.acme.sh/acme.sh --issue --dns -d $DOMAIN
                                    echo -e "${YELLOW}请按照上面的提示添加 TXT 记录，然后按回车继续${NC}"
                                    read -p "按回车继续..." CONTINUE
                                    ;;
                                8) # 其他
                                    echo -e "${YELLOW}请访问 https://github.com/acmesh-official/acme.sh/wiki/dnsapi 查看支持的 DNS 提供商列表${NC}"
                                    echo -e "${YELLOW}使用手动 DNS 验证...${NC}"
                                    ~/.acme.sh/acme.sh --issue --dns -d $DOMAIN
                                    echo -e "${YELLOW}请按照上面的提示添加 TXT 记录，然后按回车继续${NC}"
                                    read -p "按回车继续..." CONTINUE
                                    ;;
                                *)
                                    echo -e "${RED}无效选项，使用手动 DNS 验证...${NC}"
                                    ~/.acme.sh/acme.sh --issue --dns -d $DOMAIN
                                    echo -e "${YELLOW}请按照上面的提示添加 TXT 记录，然后按回车继续${NC}"
                                    read -p "按回车继续..." CONTINUE
                                    ;;
                            esac
                            ;;
                    esac
                    
                    # 证书安装位置
                    echo -e "${YELLOW}请选择证书安装位置:${NC}"
                    echo -e "  1) 默认位置 (/root/private.key 和 /root/cert.crt)"
                    echo -e "  2) 系统默认位置 (/etc/ssl/private/private.key 和 /etc/ssl/certs/cert.crt)"
                    echo -e "  3) 自定义位置"
                    read -p "选择 [1-3] (默认: 1): " CERT_LOCATION
                    CERT_LOCATION=${CERT_LOCATION:-1}
                    
                    case $CERT_LOCATION in
                        1) # root目录
                            KEY_FILE="/root/private.key"
                            CERT_FILE="/root/cert.crt"
                            ;;
                        2) # 系统默认位置
                            KEY_FILE="/etc/ssl/private/private.key"
                            CERT_FILE="/etc/ssl/certs/cert.crt"
                            # 确保目录存在
                            mkdir -p /etc/ssl/private /etc/ssl/certs
                            chmod 700 /etc/ssl/private
                            ;;
                        3) # 自定义位置
                            echo -e "${YELLOW}请输入私钥文件路径:${NC}"
                            read -p "私钥路径: " KEY_FILE
                            echo -e "${YELLOW}请输入证书文件路径:${NC}"
                            read -p "证书路径: " CERT_FILE
                            if [ -f "$KEY_FILE" ] || [ -f "$CERT_FILE" ]; then
                                echo -e "${YELLOW}警告: 目标位置可能已存在证书文件${NC}"
                                echo -e "${YELLOW}建议先备份现有文件${NC}"
                                read -p "是否继续? (Y/N): " CONTINUE
                                if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
                                    echo -e "${RED}已取消证书安装${NC}"
                                    return
                                fi
                            fi
                            ;;
                        *)
                            echo -e "${RED}无效选项，使用默认位置${NC}"
                            KEY_FILE="/root/private.key"
                            CERT_FILE="/root/cert.crt"
                            ;;
                    esac
                    
                    # 创建目录（如果不存在）
                    mkdir -p "$(dirname "$KEY_FILE")" "$(dirname "$CERT_FILE")"
                    
                    # 安装证书
                    ~/.acme.sh/acme.sh --installcert -d $DOMAIN --key-file "$KEY_FILE" --fullchain-file "$CERT_FILE"
                    
                    echo -e "${GREEN}证书已安装到: $KEY_FILE 和 $CERT_FILE${NC}"
                    
                    # 自动设置证书自动更新（不再询问）
                    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
                    echo -e "${GREEN}已设置证书自动更新${NC}"

                    # 在证书安装完成后添加
                    if [ -f "$CERT_FILE" ]; then
                        echo -e "${YELLOW}证书信息:${NC}"
                        echo -e "${YELLOW}----------------------------------------${NC}"
                        echo -e "${YELLOW}颁发给: $(openssl x509 -noout -subject -in "$CERT_FILE" | sed 's/subject=//g')${NC}"
                        echo -e "${YELLOW}颁发者: $(openssl x509 -noout -issuer -in "$CERT_FILE" | sed 's/issuer=//g')${NC}"
                        echo -e "${YELLOW}有效期: $(openssl x509 -noout -dates -in "$CERT_FILE" | sed 's/notBefore=//g' | sed 's/notAfter=//g')${NC}"
                        echo -e "${YELLOW}----------------------------------------${NC}"
                    fi

                    # 在证书安装完成后添加
                    if [ -f "$KEY_FILE" ] && [ -f "$CERT_FILE" ]; then
                        BACKUP_DIR="/root/cert_backup/$(date +%Y%m%d%H%M%S)"
                        mkdir -p "$BACKUP_DIR"
                        cp "$KEY_FILE" "$BACKUP_DIR/private.key"
                        cp "$CERT_FILE" "$BACKUP_DIR/cert.crt"
                        echo -e "${GREEN}证书已备份到: $BACKUP_DIR${NC}"
                    fi
                fi
                ;;
            5) # 自定义已有证书
                echo -e "${YELLOW}请输入私钥文件路径:${NC}"
                read -p "私钥路径: " CUSTOM_KEY_FILE
                echo -e "${YELLOW}请输入证书文件路径:${NC}"
                read -p "证书路径: " CUSTOM_CERT_FILE
                
                if [ -f "$CUSTOM_KEY_FILE" ] && [ -f "$CUSTOM_CERT_FILE" ]; then
                    echo -e "${YELLOW}请输入证书安装目标路径 (私钥):${NC}"
                    read -p "目标私钥路径 (默认: /root/private.key): " TARGET_KEY_FILE
                    TARGET_KEY_FILE=${TARGET_KEY_FILE:-"/root/private.key"}
                    
                    echo -e "${YELLOW}请输入证书安装目标路径 (证书):${NC}"
                    read -p "目标证书路径 (默认: /root/cert.crt): " TARGET_CERT_FILE
                    TARGET_CERT_FILE=${TARGET_CERT_FILE:-"/root/cert.crt"}
                    
                    # 创建目录（如果不存在）
                    mkdir -p "$(dirname "$TARGET_KEY_FILE")" "$(dirname "$TARGET_CERT_FILE")"
                    
                    # 复制证书
                    cp "$CUSTOM_KEY_FILE" "$TARGET_KEY_FILE"
                    cp "$CUSTOM_CERT_FILE" "$TARGET_CERT_FILE"
                    
                    echo -e "${GREEN}证书已安装到: $TARGET_KEY_FILE 和 $TARGET_CERT_FILE${NC}"
                else
                    echo -e "${RED}错误: 无法找到指定的证书文件${NC}"
                    echo -e "${RED}私钥文件: $CUSTOM_KEY_FILE${NC}"
                    echo -e "${RED}证书文件: $CUSTOM_CERT_FILE${NC}"
                fi
                ;;
            *)
                echo -e "${RED}无效选项，跳过证书安装${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}您选择了不申请SSL证书${NC}"
    fi
    
    echo -e "${GREEN}证书配置完成${NC}"
}

# 添加新的函数
configure_firewall() {
    echo -e "${YELLOW}[+] 配置基本防火墙规则...${NC}"
    
    # 安装ufw
    apt install -y ufw
    
    # 配置基本规则
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # 询问是否开启其他端口
    echo -e "${YELLOW}是否需要开启其他端口? (Y/N)${NC}"
    read -p "选择 [Y/N] (默认: N): " OPEN_PORTS
    if [[ "$OPEN_PORTS" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}请输入需要开启的端口，多个端口用空格分隔 (例如: 8080 8443):${NC}"
        read -p "端口: " PORTS
        for PORT in $PORTS; do
            ufw allow $PORT/tcp
            ufw allow $PORT/udp
            echo -e "${GREEN}已开启端口: $PORT${NC}"
        done
    fi
    
    # 启用防火墙
    echo -e "${YELLOW}是否立即启用防火墙? (Y/N)${NC}"
    read -p "选择 [Y/N] (默认: Y): " ENABLE_UFW
    if [[ ! "$ENABLE_UFW" =~ ^[Nn]$ ]]; then
        echo "y" | ufw enable
        echo -e "${GREEN}防火墙已启用${NC}"
    else
        echo -e "${YELLOW}防火墙配置已完成但未启用，可以稍后手动启用: sudo ufw enable${NC}"
    fi
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
    
    # 添加证书信息
    if [ -f "/root/cert.crt" ]; then
        echo -e "${YELLOW}证书信息:${NC}"
        echo -e "  证书位置: /root/cert.crt"
        echo -e "  私钥位置: /root/private.key"
        echo -e "  证书域名: $(openssl x509 -noout -subject -in /root/cert.crt | grep -oP 'CN = \K[^ ,]+')"
        echo -e "  到期时间: $(openssl x509 -noout -enddate -in /root/cert.crt | cut -d= -f2)"
    elif [ -f "/etc/ssl/certs/cert.crt" ]; then
        echo -e "${YELLOW}证书信息:${NC}"
        echo -e "  证书位置: /etc/ssl/certs/cert.crt"
        echo -e "  私钥位置: /etc/ssl/private/private.key"
        echo -e "  证书域名: $(openssl x509 -noout -subject -in /etc/ssl/certs/cert.crt | grep -oP 'CN = \K[^ ,]+')"
        echo -e "  到期时间: $(openssl x509 -noout -enddate -in /etc/ssl/certs/cert.crt | cut -d= -f2)"
    fi
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${GREEN}===== 基础环境安装完成 =====${NC}"
    echo -e "${GREEN}===== 现在可以安装应用程序了 =====${NC}"
    echo -e "${BLUE}=================================================${NC}"
    
    # 添加常用命令提示
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  查看系统状态: ${GREEN}systemctl status${NC}"
    echo -e "  查看证书信息: ${GREEN}openssl x509 -text -noout -in 证书路径${NC}"
    echo -e "  手动更新证书: ${GREEN}~/.acme.sh/acme.sh --renew -d 您的域名${NC}"
    echo -e "  查看BBR状态: ${GREEN}sysctl net.ipv4.tcp_congestion_control${NC}"
    echo -e "${BLUE}=================================================${NC}"

    echo -e "${BLUE}=================================================${NC}"
    echo -e "${WHITE}${RED}★★★ 重要提示 ★★★${NC}"
    echo -e "${CYAN}服务器管理面板已安装!${NC}"
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
    
    # 添加证书信息
    if [ -f "/root/cert.crt" ]; then
        echo "证书位置: /root/cert.crt" >> $CONFIG_FILE
        echo "私钥位置: /root/private.key" >> $CONFIG_FILE
        echo "证书域名: $(openssl x509 -noout -subject -in /root/cert.crt | grep -oP 'CN = \K[^ ,]+')" >> $CONFIG_FILE
        echo "到期时间: $(openssl x509 -noout -enddate -in /root/cert.crt | cut -d= -f2)" >> $CONFIG_FILE
    elif [ -f "/etc/ssl/certs/cert.crt" ]; then
        echo "证书位置: /etc/ssl/certs/cert.crt" >> $CONFIG_FILE
        echo "私钥位置: /etc/ssl/private/private.key" >> $CONFIG_FILE
        echo "证书域名: $(openssl x509 -noout -subject -in /etc/ssl/certs/cert.crt | grep -oP 'CN = \K[^ ,]+')" >> $CONFIG_FILE
        echo "到期时间: $(openssl x509 -noout -enddate -in /etc/ssl/certs/cert.crt | cut -d= -f2)" >> $CONFIG_FILE
    fi
    
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
    echo -e "${YELLOW}是否配置BBR? (Y/N)${NC}"
    read -p "选择 [Y/N] (默认: Y): " CONFIGURE_BBR
    if [[ ! "$CONFIGURE_BBR" =~ ^[Nn]$ ]]; then
        configure_bbr
    else
        echo -e "${YELLOW}跳过BBR配置${NC}"
    fi
    install_cert
    configure_firewall
    enhance_security
    show_results
    generate_config_summary
    install_panel
}

# 执行主函数
main
