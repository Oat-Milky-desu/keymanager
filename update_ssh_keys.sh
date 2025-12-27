#!/bin/bash

# SSH 公钥管理脚本
# 功能：将 VPS 上的 authorized_keys 替换为 JSON 文件中定义的公钥
# 适用系统：Debian

set -e

# 配置
JSON_URL="https://ba.sh/8b2R"  # 远程 JSON 链接
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 jq 是否安装
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_info "正在安装 jq..."
        apt-get update && apt-get install -y jq
    fi
}

# 获取 JSON 内容
get_json_content() {
    log_info "从远程 URL 获取 JSON: $JSON_URL"
    curl -sL "$JSON_URL"
}

# 提取公钥
extract_keys() {
    local json_content="$1"
    echo "$json_content" | jq -r '.devices[].key'
}

# 备份当前 authorized_keys
backup_authorized_keys() {
    if [ -f "$AUTHORIZED_KEYS" ]; then
        local backup_file="${AUTHORIZED_KEYS}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$AUTHORIZED_KEYS" "$backup_file"
        log_info "已备份现有 authorized_keys 到: $backup_file"
    fi
}

# 更新 authorized_keys
update_authorized_keys() {
    local json_content="$1"
    
    # 确保 .ssh 目录存在
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        log_info "创建 .ssh 目录: $SSH_DIR"
    fi
    
    # 备份现有文件
    backup_authorized_keys
    
    # 清空并写入新的公钥
    > "$AUTHORIZED_KEYS"
    
    local key_count=0
    while IFS= read -r key; do
        if [ -n "$key" ]; then
            echo "$key" >> "$AUTHORIZED_KEYS"
            ((key_count++))
        fi
    done <<< "$(extract_keys "$json_content")"
    
    # 设置正确的权限
    chmod 600 "$AUTHORIZED_KEYS"
    
    log_info "已更新 authorized_keys，共写入 $key_count 个公钥"
}

# 显示当前公钥
show_current_keys() {
    log_info "当前 authorized_keys 内容:"
    echo "----------------------------------------"
    if [ -f "$AUTHORIZED_KEYS" ]; then
        cat "$AUTHORIZED_KEYS"
    else
        echo "(文件不存在)"
    fi
    echo "----------------------------------------"
}

# 显示 JSON 中的设备列表
show_devices() {
    local json_content="$1"
    log_info "JSON 中的设备列表:"
    echo "----------------------------------------"
    echo "$json_content" | jq -r '.devices[] | "设备: \(.name)\n密钥: \(.key)\n"'
    echo "----------------------------------------"
}

# 主函数
main() {
    echo "========================================"
    echo "       SSH 公钥管理脚本"
    echo "========================================"
    echo ""
    
    # 检查是否为 root 用户或指定了用户目录
    if [ "$EUID" -eq 0 ] && [ "$SSH_DIR" = "$HOME/.ssh" ]; then
        log_warn "以 root 用户运行，将更新 root 用户的 authorized_keys"
        log_warn "如需更新其他用户，请修改 SSH_DIR 变量"
    fi
    
    # 检查依赖
    check_jq
    
    # 获取 JSON 内容
    local json_content
    json_content=$(get_json_content)
    
    # 验证 JSON 格式
    if ! echo "$json_content" | jq empty 2>/dev/null; then
        log_error "JSON 格式无效"
        log_error "获取到的内容如下："
        echo "$json_content"
        exit 1
    fi
    
    # 显示设备列表
    show_devices "$json_content"
    
    # 显示更新前的状态
    log_info "更新前的状态:"
    show_current_keys
    
    # 询问用户确认
    read -p "是否继续更新 authorized_keys? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "操作已取消"
        exit 0
    fi
    
    # 执行更新
    update_authorized_keys "$json_content"
    
    # 显示更新后的状态
    log_info "更新后的状态:"
    show_current_keys
    
    log_info "操作完成！"
    log_warn "请保持当前 SSH 连接，新开一个终端测试密钥登录是否正常"
}

# 运行主函数
main "$@"
