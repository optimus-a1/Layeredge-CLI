#!/bin/bash

# LayerEdge Light Node 安装脚本与交互菜单 for Ubuntu 24.04.2 LTS
# 本脚本提供一个菜单驱动界面用于安装和管理 LayerEdge Light Node

# 颜色代码以提高可读性
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

# 函数以打印彩色消息
print_message() {
    echo -e "${BLUE}[LayerEdge 安装]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查脚本是否以 root 身份运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请以 root 身份运行或使用 sudo"
        exit 1
    fi
}

# 创建目录
create_directories() {
    mkdir -p $LOG_DIR
    chmod 755 $LOG_DIR
}

# 更新系统并安装基本依赖
update_system() {
    print_message "正在更新系统并安装基本依赖..."
    apt-get update && apt-get upgrade -y
    apt-get install -y build-essential curl wget git pkg-config libssl-dev jq ufw
    print_success "系统更新并安装依赖完成"
}

# 安装 Go
install_go() {
    print_message "正在安装 Go 1.23..."
    wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
    rm go1.23.0.linux-amd64.tar.gz
    print_success "Go 1.23 安装成功"
}

# 检查 Go 是否安装
check_go() {
    if ! command -v go &>/dev/null; then
        install_go
    else
        go_version=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$(echo -e "1.18\n$go_version" | sort -V | head -n1)" != "1.18" ]; then
            print_warning "Go 版本低于 1.18，正在更新..."
            install_go
        else
            print_success "Go 版本 $go_version 已安装"
        fi
    fi
}

# 安装 Rust
install_rust() {
    print_message "正在安装 Rust 1.81.0+..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_success "Rust 安装成功"
}

# 检查 Rust 是否安装
check_rust() {
    if ! command -v rustc &>/dev/null; then
        install_rust
    else
        rust_version=$(rustc --version | awk '{print $2}')
        if [ "$(echo -e "1.81.0\n$rust_version" | sort -V | head -n1)" != "1.81.0" ]; then
            print_warning "Rust 版本低于 1.81.0，正在更新..."
            rustup update
        else
            print_success "Rust 版本 $rust_version 已安装"
        fi
    fi
}

# 安装 Risc0 工具链
install_risc0() {
    print_message "正在安装 Risc0 工具链..."
    curl -L https://risczero.com/install | bash
    export PATH="$HOME/.risc0/bin:$PATH"
    rzup install
    print_success "Risc0 工具链安装成功"
}

# 克隆 LayerEdge Light Node 仓库
clone_repo() {
    print_message "正在克隆 LayerEdge Light Node 仓库..."
    cd $HOME_DIR
    if [ -d "$LAYEREDGE_DIR" ]; then
        print_warning "已存在 'light-node' 目录，正在更新..."
        cd $LAYEREDGE_DIR
        git pull
    else
        git clone https://github.com/Layer-Edge/light-node.git
        cd $LAYEREDGE_DIR
    fi
    print_success "仓库克隆成功"
}

# 设置环境变量
setup_env() {
    print_message "正在设置环境变量..."

    # 检查 .env 文件是否存在
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env 文件已存在。您希望覆盖它吗？(y/n)"
        read -r overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_message "保留现有 .env 文件"
            return
        fi
    fi

    # 创建新的 .env 文件
    cat >$ENV_FILE <<EOF
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
EOF

    # 请求私钥
    read -p "请输入您的 CLI 节点私钥（不含 '0x'，或按 Enter 键跳过设置）: " private_key
    if [ ! -z "$private_key" ]; then
        echo "PRIVATE_KEY=$private_key" >>$ENV_FILE
        print_success "私钥已添加"
    else
        print_warning "未设置私钥。您需要在 .env 文件中手动设置"
    fi

    # 设置适当的权限
    chmod 644 $ENV_FILE
    print_success "环境变量配置完成"
}

# 构建 Merkle 服务
build_merkle() {
    print_message "正在构建 Risc0 Merkle 服务..."
    cd $LAYEREDGE_DIR/risc0-merkle-service
    source $HOME/.cargo/env
    cargo build
    print_success "Merkle 服务构建成功"
}

# 构建 Light Node
build_node() {
    print_message "正在构建 LayerEdge Light Node..."
    cd $LAYEREDGE_DIR
    export GOROOT=/usr/local/go
    export PATH=$GOROOT/bin:$PATH
    go build
    print_success "Light Node 构建成功"
}

# 创建 systemd 服务
create_services() {
    print_message "正在创建 Merkle 服务的 systemd 服务..."
    cat >/etc/systemd/system/layeredge-merkle.service <<EOF
[Unit]
Description=LayerEdge Merkle 服务
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR/risc0-merkle-service
ExecStart=$HOME/.cargo/bin/cargo run
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/merkle.log
StandardError=append:$LOG_DIR/merkle-error.log

[Install]
WantedBy=multi-user.target
EOF

    print_message "正在创建 Light Node 的 systemd 服务..."
    cat >/etc/systemd/system/layeredge-node.service <<EOF
[Unit]
Description=LayerEdge Light Node
After=layeredge-merkle.service
Requires=layeredge-merkle.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$LAYEREDGE_DIR/light-node
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/node.log
StandardError=append:$LOG_DIR/node-error.log

[Install]
WantedBy=multi-user.target
EOF

    # 设置适当的权限
    chmod 644 /etc/systemd/system/layeredge-merkle.service
    chmod 644 /etc/systemd/system/layeredge-node.service
    print_success "Systemd 服务已创建"
}

# 配置防火墙
setup_firewall() {
    print_message "正在配置防火墙..."
    ufw allow 22/tcp
    ufw allow 3001/tcp
    ufw allow 9090/tcp
    ufw --force enable
    print_success "防火墙配置完成"
}

# 启用并启动服务
start_services() {
    print_message "启用并启动服务..."
    systemctl daemon-reload
    systemctl enable layeredge-merkle.service
    systemctl enable layeredge-node.service
    systemctl start layeredge-merkle.service
    print_message "正在等待 Merkle 服务初始化（30秒）..."
    sleep 30
    systemctl start layeredge-node.service

    # 检查服务状态
    if systemctl is-active --quiet layeredge-merkle.service; then
        print_success "Merkle 服务正在运行"
    else
        print_error "Merkle 服务启动失败。请检查日志：journalctl -u layeredge-merkle.service"
    fi

    if systemctl is-active --quiet layeredge-node.service; then
        print_success "Light Node 正在运行"
    else
        print_error "Light Node 启动失败。请检查日志：journalctl -u layeredge-node.service"
    fi
}

# 停止服务
stop_services() {
    print_message "正在停止 LayerEdge 服务..."
    systemctl stop layeredge-node.service
    systemctl stop layeredge-merkle.service
    print_success "服务已停止"
}

# 创建状态检查脚本
create_status_script() {
    print_message "正在创建状态检查脚本..."
    cat >$HOME_DIR/check-layeredge-status.sh <<EOF
#!/bin/bash

echo "===== LayerEdge 服务状态 ====="
systemctl status layeredge-merkle.service | grep "Active:"
systemctl status layeredge-node.service | grep "Active:"

echo -e "\n===== Merkle 日志最后 10 行 ====="
tail -n 10 $LOG_DIR/merkle.log

echo -e "\n===== Node 日志最后 10 行 ====="
tail -n 10 $LOG_DIR/node.log

echo -e "\n===== 错误日志最后 10 行 ====="
tail -n 10 $LOG_DIR/merkle-error.log
tail -n 10 $LOG_DIR/node-error.log
EOF

    chmod +x $HOME_DIR/check-layeredge-status.sh
    print_success "状态检查脚本已创建：$HOME_DIR/check-layeredge-status.sh"
}

# 查看日志
view_logs() {
    echo -e "\n${CYAN}可用日志:${NC}"
    echo "1) Merkle 服务日志"
    echo "2) Light Node 日志"
    echo "3) Merkle 错误日志"
    echo "4) Light Node 错误日志"
    echo "5) 返回主菜单"

    read -p "选择查看的日志： " log_choice

    case $log_choice in
    1) less $LOG_DIR/merkle.log ;;
    2) less $LOG_DIR/node.log ;;
    3) less $LOG_DIR/merkle-error.log ;;
    4) less $LOG_DIR/node-error.log ;;
    5) return ;;
    *) print_error "选择无效" ;;
    esac
}

# 检查节点状态
check_status() {
    $HOME_DIR/check-layeredge-status.sh
}

# 查看服务状态
view_service_status() {
    echo -e "\n${CYAN}服务状态:${NC}"
    echo "1) Merkle 服务状态"
    echo "2) Light Node 服务状态"
    echo "3) 返回主菜单"

    read -p "选择服务： " service_choice

    case $service_choice in
    1)
        systemctl status layeredge-merkle.service
        read -p "按 Enter 键继续..."
        ;;

    2)
        systemctl status layeredge-node.service
        read -p "按 Enter 键继续..."
        ;;

    3) return ;;
    *) print_error "选择无效" ;;
    esac
}

# 更新私钥
update_private_key() {
    read -p "请输入您的新 CLI 节点私钥（不含 '0x'）: " new_private_key

    if [ -f "$ENV_FILE" ]; then
        # 检查 .env 中是否已存在 PRIVATE_KEY
        if grep -q "PRIVATE_KEY" "$ENV_FILE"; then
            # 替换现有的 PRIVATE_KEY
            sed -i "s/PRIVATE_KEY=.*/PRIVATE_KEY=$new_private_key/" $ENV_FILE
        else
            # 添加新的 PRIVATE_KEY
            echo "PRIVATE_KEY=$new_private_key" >>$ENV_FILE
        fi
        print_success "私钥已更新"

        # 重启 Light Node 服务以应用更改
        print_message "正在重启 Light Node 服务以应用更改..."
        systemctl restart layeredge-node.service
    else
        print_error ".env 文件未找到。请先运行设置。"
    fi
}

get_public_key() {
    LOG_FILE="$LOG_DIR/node-error.log"

    # 检查日志文件是否存在
    if [ ! -f "$LOG_FILE" ]; then
        print_error "未找到节点日志文件！"
        return 1
    fi

    # 提取最近的公钥
    PUBLIC_KEY=$(grep "Compressed Public Key: " "$LOG_FILE" | awk -F': ' '{print $2}' | tail -n1)

    if [ -z "$PUBLIC_KEY" ]; then
        print_error "日志中未找到公钥"
    else
        echo -e "\n${GREEN}=== 压缩公钥 ===${NC}"
        echo "$PUBLIC_KEY"

        # 可选：如果安装了 xclip，复制到剪贴板
        if command -v xclip &>/dev/null; then
            echo "$PUBLIC_KEY" | xclip -selection clipboard
            print_success "密钥已复制到剪贴板！"
        fi
    fi
}

# 卸载 LayerEdge
uninstall_layeredge() {
    print_message "开始 LayerEdge 卸载过程..."

    # 确认卸载
    echo -e "${RED}警告：这将完全从您的系统中移除 LayerEdge Light Node。${NC}"
    echo -e "${RED}所有数据、服务和配置将被删除。${NC}"
    read -p "您确定要继续吗？(y/n): " confirm

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_message "卸载已取消"
        return
    fi

    # 停止服务
    print_message "正在停止 LayerEdge 服务..."
    systemctl stop layeredge-node.service 2>/dev/null
    systemctl stop layeredge-merkle.service 2>/dev/null

    # 禁用服务
    print_message "正在禁用服务..."
    systemctl disable layeredge-node.service 2>/dev/null
    systemctl disable layeredge-merkle.service 2>/dev/null

    # 移除服务文件
    print_message "正在移除 systemd 服务文件..."
    rm -f /etc/systemd/system/layeredge-node.service
    rm -f /etc/systemd/system/layeredge-merkle.service
    systemctl daemon-reload

    # 移除日志目录
    print_message "正在移除日志文件..."
    rm -rf $LOG_DIR

    # 移除 LayerEdge 目录
    print_message "正在移除 LayerEdge 目录..."
    rm -rf $LAYEREDGE_DIR

    # 移除状态检查脚本
    print_message "正在移除状态检查脚本..."
    rm -f $HOME_DIR/check-layeredge-status.sh

    print_message "============================================"
    print_success "LayerEdge Light Node 已成功卸载！"
    print_message "注：本脚本未移除 Go、Rust 或 Risc0 安装。"
    print_message "============================================"
    read -p "按 Enter 键继续..."
}

# 展示仪表板连接信息
show_dashboard_info() {
    echo -e "\n${CYAN}======= LayerEdge 仪表板连接信息 =======${NC}"
    echo "1. 访问 dashboard.layeredge.io"
    echo "2. 连接您的钱包"
    echo "3. 链接您的 CLI 节点公钥"
    echo "4. 在以下地址检查您的积分："
    echo "   https://light-node.layeredge.io/api/cli-node/points/{your-wallet-address}"
    echo -e "${CYAN}=========================================================${NC}"

    read -p "按 Enter 键继续..."
}

# 全部安装
install_full() {
    check_root
    create_directories
    update_system
    check_go
    check_rust
    install_risc0
    clone_repo
    setup_env
    build_merkle
    build_node
    create_services
    setup_firewall
    create_status_script
    start_services

    print_message "============================================"
    print_success "LayerEdge Light Node 全部安装完成！"
    print_message "============================================"
    read -p "按 Enter 键继续..."
}

# 展示标语
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║               LayerEdge Light Node 管理器               ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo "By : https://x.com/theTCS_"
    echo "Version : 1.3"
    echo -e "${NC}"
}

# 主菜单
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}安装选项:${NC}"
        echo "1) 全部安装"
        echo "2) 更新仓库"
        echo "3) 构建/重建服务"
        echo ""
        echo -e "${CYAN}服务管理:${NC}"
        echo "4) 启动服务"
        echo "5) 停止服务"
        echo "6) 重启服务"
        echo "7) 查看服务状态"
        echo ""
        echo -e "${CYAN}监控与配置:${NC}"
        echo "8)  检查节点状态"
        echo "9)  查看日志"
        echo "10) 更新私钥"
        echo "11) 获取公钥"
        echo "12) 仪表板连接信息"
        echo "13) 卸载 LayerEdge"
        echo ""
        echo "14) 退出"
        echo ""
        read -p "请输入您的选择： " choice

        case $choice in
        1) install_full ;;
        2)
            check_root
            clone_repo
            read -p "按 Enter 键继续..."
            ;;
        3)
            check_root
            build_merkle
            build_node
            read -p "按 Enter 键继续..."
            ;;
        4)
            check_root
            start_services
            read -p "按 Enter 键继续..."
            ;;
        5)
            check_root
            stop_services
            read -p "按 Enter 键继续..."
            ;;
        6)
            check_root
            stop_services
            start_services
            read -p "按 Enter 键继续..."
            ;;
        7)
            check_root
            view_service_status
            ;;
        8)
            check_status
            read -p "按 Enter 键继续..."
            ;;
        9)
            view_logs
            ;;
        10)
            check_root
            update_private_key
            read -p "按 Enter 键继续..."
            ;;
        11)
            check_root
            get_public_key
            read -p "按 Enter 键继续..."
            ;;
        12)
            show_dashboard_info
            ;;
        13)
            check_root
            uninstall_layeredge
            ;;
        14)
            echo "正在退出 LayerEdge Light Node 管理器。再见！"
            exit 0
            ;;
        *)
            print_error "无效选项。请再试一次。"
            read -p "按 Enter 键继续..."
            ;;
        esac
    done
}

# 执行主菜单
main_menu
