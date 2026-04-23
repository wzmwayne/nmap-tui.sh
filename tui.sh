#!/bin/sh
# Nmap TUI 包装脚本 (使用 whiptail)
# 依赖: nmap, whiptail

# 检查必要命令
if ! command -v nmap >/dev/null 2>&1; then
    echo "错误: 未找到 nmap，请先安装 nmap。" >&2
    exit 1
fi

if ! command -v whiptail >/dev/null 2>&1; then
    echo "错误: 未找到 whiptail，请安装 whiptail 或 dialog。" >&2
    echo "Debian/Ubuntu: sudo apt install whiptail" >&2
    exit 1
fi

# 临时文件保存扫描结果
TMPFILE=$(mktemp /tmp/nmap_result.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

# 主循环
while true; do
    CHOICE=$(whiptail --title "Nmap TUI" --menu "选择一个操作" 20 70 12 \
        "1" "快速扫描 (常用 100 端口)" \
        "2" "全端口扫描 (1-65535)" \
        "3" "服务/版本检测 (-sV)" \
        "4" "操作系统检测 (-O)" \
        "5" "UDP 端口扫描" \
        "6" "综合扫描 (服务+OS+默认脚本)" \
        "7" "自定义参数扫描" \
        "8" "查看上次扫描结果" \
        "9" "退出" 3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && break  # 用户取消

    case "$CHOICE" in
        1) SCAN_TYPE="-F"; DESC="快速扫描" ;;
        2) SCAN_TYPE="-p-"; DESC="全端口扫描" ;;
        3) SCAN_TYPE="-sV"; DESC="服务/版本检测" ;;
        4) SCAN_TYPE="-O"; DESC="操作系统检测" ;;
        5) SCAN_TYPE="-sU"; DESC="UDP 端口扫描" ;;
        6) SCAN_TYPE="-sS -sV -O -sC"; DESC="综合扫描" ;;
        7) SCAN_TYPE=""; DESC="自定义扫描" ;;
        8)
            if [ -f "$TMPFILE" ] && [ -s "$TMPFILE" ]; then
                whiptail --title "上次扫描结果" --textbox "$TMPFILE" 30 100 --scrolltext
            else
                whiptail --msgbox "暂无扫描结果。" 8 40
            fi
            continue
            ;;
        9) break ;;
        *) continue ;;
    esac

    # 获取目标
    TARGET=$(whiptail --title "目标" --inputbox "输入目标 IP 地址、域名或网段\n例如: 192.168.1.1 或 scanme.nmap.org 或 10.0.0.0/24" 12 60 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && continue
    [ -z "$TARGET" ] && whiptail --msgbox "目标不能为空！" 8 40 && continue

    # 如果是自定义扫描，让用户输入额外参数
    if [ "$CHOICE" = "7" ]; then
        CUSTOM_ARGS=$(whiptail --title "自定义参数" --inputbox "输入 nmap 参数 (不含目标)" 10 60 "-sS -sV -p 22,80,443" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        SCAN_TYPE="$CUSTOM_ARGS"
    fi

    # 是否保存输出
    OUTPUT_OPT=""
    SAVE_CHOICE=$(whiptail --title "输出选项" --menu "是否将结果保存到文件？" 12 50 3 \
        "1" "仅屏幕显示（不保存）" \
        "2" "保存为普通文本 (-oN)" \
        "3" "保存为 XML (-oX)" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && continue

    case "$SAVE_CHOICE" in
        2) OUTPUT_OPT="-oN ${TMPFILE}.txt" ;;
        3) OUTPUT_OPT="-oX ${TMPFILE}.xml" ;;
        *) OUTPUT_OPT="" ;;
    esac

    # 组装命令并执行
    CMD="nmap $SCAN_TYPE $OUTPUT_OPT $TARGET"
    whiptail --title "执行扫描" --infobox "正在扫描，请稍候...\n命令: $CMD" 8 70
    # 运行并将标准输出和错误重定向到临时文件
    eval "$CMD" > "$TMPFILE" 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        whiptail --title "扫描完成 - $DESC" --textbox "$TMPFILE" 30 100 --scrolltext
    else
        whiptail --title "扫描失败" --msgbox "nmap 执行出错，返回码: $EXIT_CODE\n\n$(cat "$TMPFILE")" 20 70
    fi
done

whiptail --title "再见" --msgbox "感谢使用 Nmap TUI。" 8 40
clear
