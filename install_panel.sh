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
cat > /usr/local/bin/sb.sh << 'EOF'
#!/bin/bash

# 面板脚本内容
# 这里粘贴上面的sb.sh完整内容
EOF

# 设置执行权限
chmod +x /usr/local/bin/sb.sh

# 创建快捷命令
echo -e "${YELLOW}创建快捷命令 'sb'...${NC}"
ln -sf /usr/local/bin/sb.sh /usr/local/bin/sb
chmod +x /usr/local/bin/sb

echo -e "${GREEN}服务器管理面板安装完成!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo -e "${YELLOW}使用方法:${NC}"
echo -e "  输入 ${GREEN}sb${NC} 命令启动管理面板"
echo -e "${BLUE}=================================================${NC}" 