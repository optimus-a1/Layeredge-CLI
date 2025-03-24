#!/bin/bash

# LayerEdge Light Node 安装脚本（适用于 Ubuntu 24.04.2 LTS）
# 由 https://x.com/theTCS_ 编写，已汉化版本 by ChatGPT

# 颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 变量
HOME_DIR=$HOME
LAYEREDGE_DIR="$HOME_DIR/light-node"
ENV_FILE="$LAYEREDGE_DIR/.env"
LOG_DIR="/var/log/layeredge"

# 打印信息函数
print_message() { echo -e "${BLUE}[LayerEdge 设置]${NC} $1"; }
print_success() { echo -e "${GREEN}[成功]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${NC} $1"; }
print_error()   { echo -e "${RED}[错误]${NC} $1"; }

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 用户或 sudo 权限运行此脚本"
        exit 1
    fi
}

# 目录和系统准备函数略（未改动）...

# （中间功能函数略，与你提供的一样未改动，仅下方中文菜单部分更新）

# 日志查看菜单（中文）
view_logs() {
    echo -e "\n${CYAN}可查看的日志文件:${NC}"
    echo "1) Merkle 服务日志"
    echo "2) Light Node 节点日志"
    echo "3) Merkle 错误日志"
    echo "4) Light Node 错误日志"
    echo "5) 返回主菜单"

    read -p "请选择要查看的日志编号: " log_choice

    case $log_choice in
    1) less $LOG_DIR/merkle.log ;;
    2) less $LOG_DIR/node.log ;;
    3) less $LOG_DIR/merkle-error.log ;;
    4) less $LOG_DIR/node-error.log ;;
    5) return ;;
    *) print_error "无效选择，请重新输入。" ;;
    esac
}

# 查看服务状态菜单（中文）
view_service_status() {
    echo -e "\n${CYAN}服务状态:${NC}"
    echo "1) Merkle 服务状态"
    echo "2) Light Node 节点服务状态"
    echo "3) 返回主菜单"

    read -p "请选择服务编号: " service_choice

    case $service_choice in
    1)
        systemctl status layeredge-merkle.service
        read -p "按回车键继续..."
        ;;
    2)
        systemctl status layeredge-node.service
        read -p "按回车键继续..."
        ;;
    3) return ;;
    *) print_error "无效选择，请重新输入。" ;;
    esac
}

# 仪表盘连接信息（中文）
show_dashboard_info() {
    echo -e "\n${CYAN}======= LayerEdge 仪表盘连接信息 =======${NC}"
    echo "1. 访问: https://dashboard.layeredge.io"
    echo "2. 连接你的钱包"
    echo "3. 绑定 CLI 节点公钥"
    echo "4. 积分查看接口:"
    echo "   https://light-node.layeredge.io/api/cli-node/points/{你的钱包地址}"
    echo -e "${CYAN}======================================${NC}"

    read -p "按回车键继续..."
}

# 显示中文 Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║         LayerEdge 轻节点管理工具（中文版）               ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo "作者 : https://x.com/theTCS_"
    echo "版本 : 1.3"
    echo -e "${NC}"
}

# 主菜单（中文版）
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}安装相关操作:${NC}"
        echo "1) 一键完整安装"
        echo "2) 更新仓库代码"
        echo "3) 编译 / 重新编译服务"
        echo ""
        echo -e "${CYAN}服务管理:${NC}"
        echo "4) 启动服务"
        echo "5) 停止服务"
        echo "6) 重启服务"
        echo "7) 查看服务状态"
        echo ""
        echo -e "${CYAN}监控与配置:${NC}"
        echo "8) 查看节点运行状态"
        echo "9) 查看日志"
        echo "10) 设置 / 更新私钥"
        echo "11) 获取 CLI 节点公钥"
        echo "12) 查看仪表盘连接信息"
        echo "13) 卸载 LayerEdge 节点"
        echo ""
        echo "14) 退出程序"
        echo ""
        read -p "请输入你的选择编号: " choice

        case $choice in
        1) install_full ;;
        2) check_root; clone_repo; read -p "按回车键继续..." ;;
        3) check_root; build_merkle; build_node; read -p "按回车键继续..." ;;
        4) check_root; start_services; read -p "按回车键继续..." ;;
        5) check_root; stop_services; read -p "按回车键继续..." ;;
        6) check_root; stop_services; start_services; read -p "按回车键继续..." ;;
        7) check_root; view_service_status ;;
        8) check_status; read -p "按回车键继续..." ;;
        9) view_logs ;;
        10) check_root; update_private_key; read -p "按回车键继续..." ;;
        11) check_root; get_public_key; read -p "按回车键继续..." ;;
        12) show_dashboard_info ;;
        13) check_root; uninstall_layeredge ;;
        14) echo "退出 LayerEdge 节点管理器，感谢使用！"; exit 0 ;;
        *) print_error "无效选项，请重新输入。"; read -p "按回车键继续..." ;;
        esac
    done
}

# 运行主菜单
main_menu
