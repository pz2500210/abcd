#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本必须以root用户身份运行${NC}"
    exit 1
fi

# 创建面板脚本
echo -e "${YELLOW}创建服务器管理面板脚本...${NC}"
# 这里应该直接复制xx.sh文件，而不是使用EOF
cp /tmp/server-setup/xx.sh /usr/local/bin/xx.sh 2>/dev/null || cp /root/xx.sh /usr/local/bin/xx.sh 2>/dev/null

# 设置执行权限
chmod +x /usr/local/bin/xx.sh

# 创建快捷命令
echo -e "${YELLOW}创建快捷命令 'xx'...${NC}"
ln -sf /usr/local/bin/xx.sh /usr/local/bin/xx
chmod +x /usr/local/bin/xx

echo -e "${GREEN}服务器管理面板安装完成!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}使用方法:${NC}"
echo -e "  输入 ${GREEN}xx${NC} 命令启动管理面板"
echo -e "${BLUE}=================================================${NC}" 