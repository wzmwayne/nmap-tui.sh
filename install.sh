#!/bin/bash
# 一键安装脚本：下载 nmap-tui 并配置别名
# 用法: curl -s https://github.com/wzmwayne/nmap-tui.sh/raw/refs/heads/main/install.sh | bash

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 下载地址
DOWNLOAD_URL="https://github.com/wzmwayne/nmap-tui.sh/raw/refs/heads/main/tui.sh"
DEFAULT_ALIAS="tnmap"
DEFAULT_DIR="$HOME"

# 检查终端交互
if [ -t 0 ]; then
    INTERACTIVE=1
else
    INTERACTIVE=0
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Nmap TUI 安装脚本${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 选择模式
if [ $INTERACTIVE -eq 1 ]; then
    echo -e "${BLUE}请选择安装模式:${NC}"
    echo "  [1] 默认模式 (安装到 $DEFAULT_DIR, 别名 $DEFAULT_ALIAS)"
    echo "  [2] 自定义模式 (自行指定安装路径与别名)"
    read -p "请输入选项 (1/2) [默认: 1]: " MODE
    if [ -z "$MODE" ]; then
        MODE=1
    fi
else
    echo -e "${YELLOW}非交互环境，自动使用默认模式。${NC}"
    MODE=1
fi

case "$MODE" in
    1)
        INSTALL_DIR="$DEFAULT_DIR"
        ALIAS_NAME="$DEFAULT_ALIAS"
        echo -e "${GREEN}✓ 已选择默认安装模式。${NC}"
        ;;
    2)
        if [ $INTERACTIVE -eq 0 ]; then
            echo -e "${YELLOW}非交互环境无法使用自定义模式，回退到默认模式。${NC}"
            INSTALL_DIR="$DEFAULT_DIR"
            ALIAS_NAME="$DEFAULT_ALIAS"
        else
            read -p "请输入安装目录 [默认: $DEFAULT_DIR]: " INSTALL_DIR
            if [ -z "$INSTALL_DIR" ]; then
                INSTALL_DIR="$DEFAULT_DIR"
            fi
            read -p "请输入命令别名 [默认: $DEFAULT_ALIAS]: " ALIAS_NAME
            if [ -z "$ALIAS_NAME" ]; then
                ALIAS_NAME="$DEFAULT_ALIAS"
            fi
            echo -e "${GREEN}✓ 自定义安装：目录 $INSTALL_DIR, 别名 $ALIAS_NAME${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}无效输入，使用默认模式。${NC}"
        INSTALL_DIR="$DEFAULT_DIR"
        ALIAS_NAME="$DEFAULT_ALIAS"
        ;;
esac

# 创建目录 (如果不存在)
mkdir -p "$INSTALL_DIR"
SCRIPT_PATH="$INSTALL_DIR/tui.sh"
ALIAS_CMD="alias $ALIAS_NAME='$SCRIPT_PATH'"

# 1. 下载脚本
echo -e "${BLUE}➤ 正在下载 tui.sh ...${NC}"
curl -s -o "$SCRIPT_PATH" "$DOWNLOAD_URL"
echo -e "${GREEN}✓ 脚本已保存到 $SCRIPT_PATH${NC}"

# 2. 赋予执行权限
chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}✓ 执行权限已设置${NC}"

# 3. 配置别名到 shell rc 文件
RC_FILES=()
if [ -f "$HOME/.bashrc" ]; then
    RC_FILES+=("$HOME/.bashrc")
fi
if [ -f "$HOME/.zshrc" ]; then
    RC_FILES+=("$HOME/.zshrc")
fi
if [ ${#RC_FILES[@]} -eq 0 ]; then
    touch "$HOME/.bashrc"
    RC_FILES+=("$HOME/.bashrc")
fi

for rc in "${RC_FILES[@]}"; do
    if ! grep -qF "$ALIAS_CMD" "$rc"; then
        echo "" >> "$rc"
        echo "# $ALIAS_NAME alias (nmap-tui)" >> "$rc"
        echo "$ALIAS_CMD" >> "$rc"
        echo -e "${GREEN}✓ 别名已添加到 $rc${NC}"
    else
        echo -e "${YELLOW}⚠ 别名已存在于 $rc，跳过${NC}"
    fi
done

# 4. 立即生效提示
echo -e "${BLUE}➤ 若要在当前终端立即使用，请执行:${NC}"
echo -e "${YELLOW}   source ~/.bashrc   # 如果使用 bash${NC}"
echo -e "${YELLOW}   source ~/.zshrc    # 如果使用 zsh${NC}"
echo -e "${GREEN}✓ 安装完成！现在可以输入 '${ALIAS_NAME}' 运行 Nmap TUI。${NC}"
