#!/bin/bash
# ============================================================
# Project: rk3318-homeassistant-installer
# Author: [CAIXYPROMISE](https://github.com/CaixyPromise)
# Version: 1.4
# Last Modified: 2025-01-19
# GitHub Repository: https://github.com/CaixyPromise/rk3318-homeassistant-installer
# 
# Copyright (c) 2025 CAIXYPROMISE
#
# This script is licensed under the MIT License. 
# You may obtain a copy of the License at https://opensource.org/licenses/MIT
# Supported Operating Systems:
# - Debian Bullseye (11) - Stable and Recommended ⭐
# - Debian Bookworm (12) - Beta, under testing and bug fixes 🔨
# Supported Architectures:
# - ARM (aarch64, armv7, armv5) - Stable and Recommended ⭐
# - AMD64 (x86_64) - Beta, under testing, potential issues with downloading or installing architecture-specific .deb packages
# ============================================================
echo "=========================================="
echo "rk3318-homeassistant-installer"
echo "Author: [CAIXYPROMISE](https://github.com/CaixyPromise)"
echo "License: MIT"
echo "GitHub repository: https://github.com/CaixyPromise/rk3318-homeassistant-installer"
echo "Version: 1.4"
echo "Last modified: 2025-02-04"
echo "Supported OS: "
echo "  - Debian Bullseye (11) - Stable and Recommended ⭐"
echo "  - Debian Bookworm (12) - Beta, under testing and bug fixes 🔨"
echo "Supported Architectures: "
echo "  - ARM (aarch64, armv7, armv5) - Stable and Recommended ⭐"
echo "  - AMD64 (x86_64) - Beta, under testing, potential issues with downloading or installing .deb packages"
echo "=========================================="
echo "💡 Tip: ⭐Star this project on GitHub to get updates and new features!"
echo "👉 Visit: https://github.com/CaixyPromise/rk3318-homeassistant-installer"
echo "=========================================="

if ! sudo -v > /dev/null 2>&1; then
    echo "❌ 脚本需要 sudo 权限，请确保用户具有 sudo 权限后重新运行。"
    exit 1
fi

# 定义全局下载目录
INITIAL_DIR=$(pwd)
HA_DOWNLOAD_DIR="$INITIAL_DIR/ha_downloads"
BKP_BASE_DIR="$INITIAL_DIR/ha_backups"
mkdir -p "$HA_DOWNLOAD_DIR" || {
    echo "❌ 无法创建下载目录：$HA_DOWNLOAD_DIR"
    exit 1
}
# 定义颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色（Reset）


check_network() {
    echo "🔍 正在检查网络连接..."
    if ! command -v ping > /dev/null; then
        echo "🚨 ping 工具不可用，跳过网络检查"
        return # 直接
    fi

    local network_ok=false
    for target in "baidu.com" "google.com" "bing.com"; do
        if ping -c 1 -W 2 "$target" > /dev/null 2>&1; then
            echo "✅ 网络连接正常：$target"
            network_ok=true
            break
        fi
    done
    if ! $network_ok; then
        echo "❌ 无法连接到任何网络，请检查您的网络连接。"
        exit 1
    fi
}


# 检查网络
check_network
prompt_yes_no() {
    local prompt_message=$1
    while true; do
        read -p "$prompt_message (Yes(Y)/No(N)): " user_input
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]' | xargs)
        if [[ -z "$user_input" ]]; then
            echo "❌ 输入不能为空，请输入 Yes(Y) 或 No(N)。"
            continue
        fi
        case "$user_input" in
            y|yes) return 0 ;;  # 用户选择 Yes，返回 true
            n|no) return 1 ;;   # 用户选择 No，返回 false
            *) echo "❌ 无效输入，请输入 Yes(Y) 或 No(N)。" ;;
        esac
    done
}

# 检查系统发行版本
if [[ "$(uname -s)" != "Linux" || "$(lsb_release -si)" != "Debian" ]]; then
    echo "❌ 本脚本目前仅支持运行在 Debian 系统上，当前系统不兼容。"
    exit 1
fi

# 检测系统版本
OS_CODENAME=$(lsb_release -sc)
if [[ "$OS_CODENAME" != "bullseye" ]]; then
    echo "Warning: This script is designed for Debian 11 Bullseye systems."
    echo "Your system is detected as: $OS_CODENAME"
    echo "It is recommended to use Debian 11 Bullseye for a stable installation."
    echo "However, the script has been tested on Debian 12 (Bookworm)."
    if ! prompt_yes_no "Your system is detected as $OS_CODENAME. Do you wish to continue the installation?"; then
        echo "用户选择退出脚本。"
        exit 0
    fi
    echo "Proceeding with the installation..."
else
    echo "System detected as Debian 11 Bullseye. Proceeding with the installation..."
fi

# 检测系统架构
ARCH=$(uname -m)
case "$ARCH" in
    "aarch64")
        OS_AGENT_REPOSITORY="https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_aarch64.deb"
        ;;
    "x86_64")
        OS_AGENT_REPOSITORY="https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_x86_64.deb"
        ;;
    "armv7l")
        OS_AGENT_REPOSITORY="https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_armv7.deb"
        ;;
    "armv5")
        OS_AGENT_REPOSITORY="https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_armv5.deb"
        ;;
    "i386" | "i686")
        OS_AGENT_REPOSITORY="https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_i386.deb"
        ;;
    *)
        echo "Error: Unsupported architecture detected ($ARCH)."
        echo "Exiting the script."
        exit 1
        ;;
esac
HACS_REPOSITORY=https://github.com/hacs/integration/releases/download/2.0.1/hacs.zip
# OS_AGENT_REPOSITORY=https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_aarch64.deb
SUPERVISED_REPOSITORY=https://github.com/home-assistant/supervised-installer/releases/download/1.8.0/homeassistant-supervised.deb

# 创建日志目录
LOG_DIR="$(pwd)/logs"
mkdir -p "$LOG_DIR" || {
    echo "❌ 日志目录创建失败：$LOG_DIR"
    exit 1
}

mkdir -p "$BKP_BASE_DIR" || {
    echo "❌ 备份目录创建失败：$BKP_BASE_DIR"
    exit 1
}


# 获取当前时间
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 打印操作系统信息
OS_INFO=$(uname -a)
echo "操作系统信息: $OS_INFO"

# 检查传入的参数 (重启次数)
RESTART_STEP=$1

BACKUP_SESSION_ID=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BKP_BASE_DIR/$BACKUP_SESSION_ID"
BACKUP_MANIFEST="$BACKUP_DIR/manifest.tsv"

start_backup_session() {
    mkdir -p "$BACKUP_DIR"
    : > "$BACKUP_MANIFEST"
}

backup_target() {
    local target="$1"
    local kind="file"
    [ -L "$target" ] && kind="symlink"

    mkdir -p "$BACKUP_DIR"
    local safe_name
    safe_name=$(echo "$target" | sed 's#^/##; s#/#__#g')
    local backup_path="$BACKUP_DIR/$safe_name"

    if [ -L "$target" ]; then
        local link_target
        link_target=$(readlink "$target")
        printf "%s\tsymlink\t%s\t%s\n" "$target" "$backup_path" "$link_target" >> "$BACKUP_MANIFEST"
    elif [ -e "$target" ]; then
        sudo cp -a "$target" "$backup_path"
        printf "%s\tfile\t%s\t\n" "$target" "$backup_path" >> "$BACKUP_MANIFEST"
    else
        printf "%s\tmissing\t\t\n" "$target" >> "$BACKUP_MANIFEST"
    fi
}

rollback_backup() {
    local session="${1:-latest}"
    local rollback_dir

    if [ "$session" = "latest" ]; then
        rollback_dir=$(find "$BKP_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)
    else
        rollback_dir="$BKP_BASE_DIR/$session"
    fi

    if [ -z "$rollback_dir" ] || [ ! -f "$rollback_dir/manifest.tsv" ]; then
        echo "❌ 未找到可回滚的备份：$session"
        exit 1
    fi

    echo "♻️ 正在根据备份回滚：$rollback_dir"
    tac "$rollback_dir/manifest.tsv" | while IFS=$'\t' read -r target type backup extra; do
        case "$type" in
            file)
                sudo cp -a "$backup" "$target"
                ;;
            symlink)
                sudo ln -sfn "$extra" "$target"
                ;;
            missing)
                sudo rm -f "$target"
                ;;
        esac
    done
    echo "✅ 回滚完成。"
}

if [ "$RESTART_STEP" = "rollback" ] || [ "$RESTART_STEP" = "--rollback" ]; then
    rollback_backup "$2"
    exit 0
fi

# 如果没有传入参数，提示用户输入
if [ -z "$RESTART_STEP" ]; then
    echo "请提供一个参数：0（第一次安装），1（第一次重启后），2（第二次重启后）"
    exit 1
fi

# 验证输入是否为有效整数且在范围内
if ! [[ "$RESTART_STEP" =~ ^[0-2]$ ]]; then
    echo "❌ 无效参数：支持参数为 0（第一次安装）、1（第一次重启后）、2（第二次重启后）。"
    echo "示例：./script.sh 0"
    exit 1
fi

# 日志文件名
LOG_FILE="$LOG_DIR/${TIMESTAMP}_stage_${RESTART_STEP}.log"

# 重定向所有输出到日志文件
exec > >(tee -a "$LOG_FILE") 2>&1
start_backup_session

auto_install_package() {
    local package_name=$1

    if [ -z "$package_name" ]; then
        echo "❌ Error: Please provide a package name."
        return 1
    fi

    echo "🔍 Querying package information for: $package_name"

    # Check if the package is already installed
    if dpkg -l | grep -qw "$package_name"; then
        echo "✅ Package '$package_name' is already installed."
        return 0
    fi

    # Get candidate version using apt-cache policy
    local policy_output
    policy_output=$(apt-cache policy "$package_name")
    local available_version
    available_version=$(echo "$policy_output" | awk '/Candidate:/ {print $2}')

    if [ -z "$available_version" ]; then
        echo "❌ No available version found for $package_name."
        return 1
    fi

    echo "🟢 Candidate version: $available_version"

    # Create a temporary directory for downloading
    local temp_dir="/$HA_DOWNLOAD_DIR/apt_download"
    mkdir -p "$temp_dir"

    # Attempt to download the package using apt-get download
    echo "📥 Downloading package $package_name..."
    cd "$temp_dir" || return
    if ! apt-get download "$package_name"; then
        echo "❌ Failed to download $package_name. Check your network or package availability."
        return 1
    fi

    # Find the downloaded package file
    local deb_file
    deb_file=$(ls | grep -E "^${package_name}_.*\.deb$" | head -n 1)

    if [ -z "$deb_file" ]; then
        echo "❌ Failed to locate the downloaded .deb file for $package_name."
        return 1
    fi

    echo "📦 Found package file: $deb_file"

    # Install the package using dpkg
    echo "📦 Installing $deb_file..."
    sudo dpkg -i "$deb_file"

    # Fix dependencies if necessary
    if [ $? -ne 0 ]; then
        echo "⚠️  Fixing broken dependencies..."
        sudo apt-get --fix-broken install -y
        sudo dpkg -i "$deb_file"
    fi

    # Verify installation
    if dpkg -l | grep -qw "$package_name"; then
        echo "✅ $package_name has been successfully installed."
    else
        echo "❌ Installation failed for $package_name."
    fi

    # Clean up temporary files
    rm -rf "$temp_dir"
    echo "🧹 Temporary files cleaned up."
}


download_with_retry() {
    URL=$1
    DEST="$HA_DOWNLOAD_DIR/$(basename $2)"
    MAX_RETRIES=3
    RETRY_COUNT=0

    while true; do
        echo "尝试下载: $URL 到 $DEST ..."
        wget "$URL" -O "$DEST"

        if [ $? -eq 0 ]; then
            echo "✅ 下载成功: $DEST"
            return 0
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "❌ 下载失败，正在重试 ($RETRY_COUNT/$MAX_RETRIES)..."
        sleep 5

        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "❌ 下载失败 $MAX_RETRIES 次，请检查网络连接。"
            if prompt_yes_no "是否继续尝试下载？"; then
                RETRY_COUNT=0
            else
                echo "用户选择退出下载，退出函数。"
                return 1
            fi
        fi
    done
}
archive_logs() {
    local mode=$1 # 归档模式：single（单阶段）或 all（所有阶段）
    local archive_name
    local unique_id
    unique_id=$(date +"%H%M%S")

    # 显式关闭日志输出流，确保文件可用
    exec > /dev/tty 2>&1

    if [[ "$mode" == "single" ]]; then
        archive_name="$LOG_DIR/logs_stage_${RESTART_STEP}_${unique_id}.tar.gz"
        if [[ ! -f "$LOG_FILE" ]]; then
            echo "❌ 日志文件不存在：$LOG_FILE"
            return 1
        fi
        tar --warning=no-file-changed -czvf "$archive_name" "$LOG_FILE" || {
            echo "错误：当前阶段日志归档失败：$archive_name"
            return 1
        }
        echo "✅ 当前阶段日志已打包：$archive_name"
    elif [[ "$mode" == "all" ]]; then
        archive_name="$INITIAL_DIR/logs_all_${TIMESTAMP}_${unique_id}.tar.gz"
        if [[ ! -d "$LOG_DIR" ]]; then
            echo "❌ 日志目录不存在：$LOG_DIR"
            return 1
        fi
        tar --warning=no-file-changed -czvf "$archive_name" -C "$LOG_DIR" . || {
            echo "错误：所有阶段日志归档失败：$archive_name"
            return 1
        }
        echo "✅ 所有阶段日志已打包：$archive_name"
    else
        echo "❌ 无效的归档模式，请指定 'single' 或 'all'"
        return 1
    fi
}

# 最大重试次数
MAX_RETRIES=5

# 包检查和安装函数
check_and_install_packages() {
    local retry_count=$1  # 当前重试次数
    local packages=("$@") # 传入的所有软件包列表（包含重试次数参数，需处理）

    # 移除第一个参数（重试次数）
    packages=("${packages[@]:1}")

    # 检查未安装的软件包
    local missing_packages=()
    for package in "${packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            echo "⚠️  $package 未安装或安装失败"
            missing_packages+=("$package")
        else
            echo "✅ $package 已安装"
        fi
    done

    # 如果有未安装的软件包
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "⚠️  需要重新安装以下未安装的软件包: ${missing_packages[*]}"

        # 更新包索引并尝试安装
        sudo apt-get update
        sudo apt-get install -y "${missing_packages[@]}"
        local failed_packages=()

        # 检查修复依赖问题并记录仍然未安装的包
        for package in "${missing_packages[@]}"; do
            if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
                failed_packages+=("$package")
            fi
        done

        # 尝试使用 auto_install_package 函数处理仍未安装的软件包
        if [ ${#failed_packages[@]} -ne 0 ]; then
            echo "🔄 使用 auto_install_package 尝试安装以下未成功的软件包: ${failed_packages[*]}"
            for package in "${failed_packages[@]}"; do
                if ! auto_install_package "$package"; then
                    echo "❌ 无法安装 $package，请手动检查或安装后重试。"
                else
                    echo "✅ $package 通过 auto_install_package 成功安装。"
                fi
            done
        fi

        # 检查是否还有未安装的软件包
        local remaining_packages=()
        for package in "${failed_packages[@]}"; do
            if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
                remaining_packages+=("$package")
            fi
        done

        if [ ${#remaining_packages[@]} -gt 0 ]; then
            echo "❌ 以下软件包仍未成功安装: ${remaining_packages[*]}"
            if [ $retry_count -lt $MAX_RETRIES ]; then
                echo "🔄 重新检查安装状态，当前重试次数：$((retry_count + 1))"
                check_and_install_packages $((retry_count + 1)) "${remaining_packages[@]}"
            else
                echo "❌ 超出最大重试次数 ($MAX_RETRIES)。请手动检查以下软件包: ${remaining_packages[*]}"
                exit 1
            fi
        else
            echo "✅ 所有软件包已成功安装。"
        fi
    else
        echo "✅ 所有软件包已成功安装，无需进一步操作。"
    fi
}


# 容器检查和启动函数
check_and_start_containers() {
    local retry_count=$1  # 当前重试次数
    local containers=("homeassistant")  # 待检查的容器列表

    echo "检查容器启动状态（第 $((retry_count + 1)) 次尝试）..."

    # 标记是否所有容器都启动
    local all_started=true

    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --format '{{.Names}}' | grep -q "$container"; then
            echo "$container 已启动。"
        else
            echo "$container 尚未启动。"
            all_started=false
        fi
    done

    # 如果所有容器都启动，结束检查
    if $all_started; then
        echo "所有容器已成功启动！"
        return 0
    fi

    # 如果未成功启动，检查重试次数
    if [ $retry_count -ge $MAX_RETRIES ]; then
        echo "已达到最大重试次数 ($MAX_RETRIES)，退出脚本。"
        exit 1
    fi

    # 尝试重新启动 Docker Compose 并递归调用检查
    echo "尝试重新启动 Docker Compose..."
    docker compose up -d

    # 延迟 10 秒后重新检查
    sleep 10
    check_and_start_containers $((retry_count + 1))
}

install_deb_with_check() {
    local deb_file=$1
    package_name=$(dpkg-deb --show --showformat='${Package}' "$deb_file")  # 包名，用于检查是否安装成功

    echo "📦 正在安装 DEB 包：$deb_file"

    # 检查文件是否存在
    if [[ ! -f "$deb_file" ]]; then
        echo "❌ 找不到 DEB 文件：$deb_file"
        return 1
    fi

    # 安装 DEB 包
    sudo dpkg -i "$deb_file"
    
    # 检查是否安装成功
    if ! dpkg -l | grep -qw "$package_name"; then
        echo "❌ 安装 $package_name 失败，正在尝试修复依赖问题..."
        sudo apt-get --fix-broken install -y
        
        # 再次尝试安装
        sudo dpkg -i "$deb_file"
        if ! dpkg -l | grep -qw "$package_name"; then
            echo "❌ 二次尝试后仍无法安装 $package_name，请检查系统状态并手动修复。"
            return 1
        fi
    fi

    echo "✅ 成功安装 $package_name"
    return 0
}

check_packages() {
    local packages=("$@")
    local missing_packages=()

    for package in "${packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            echo "⚠️  $package 未安装或安装失败"
            missing_packages+=("$package")
        else
            echo "✅ $package 已安装"
        fi
    done

    # 返回检查结果
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "❌ 以下软件包未成功安装: ${missing_packages[*]}"
        return 1
    else
        echo "✅ 所有软件包已安装成功"
        return 0
    fi
}

# 安装并检查软件包
install_and_check() {
    local packages=("$@")
    
    echo "📦 开始安装软件包..."
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
    
    echo "🔍 检查软件包安装状态..."
    check_packages "${packages[@]}"
    
    if [ $? -ne 0 ]; then
        echo "⚠️  检测到部分软件包未正确安装，尝试重新安装..."
        sudo apt-get install -y "${packages[@]}"
        
        echo "🔍 再次检查软件包安装状态..."
        check_packages "${packages[@]}"
        
        if [ $? -ne 0 ]; then
            echo "❌ 部分软件包仍未正确安装，请手动检查以下软件包:"
            check_packages "${packages[@]}"
            exit 1
        fi
    fi
}

# 获取系统发行版本代号
OS_CODENAME=$(lsb_release -sc)

# 检查并添加源的函数
add_source_if_not_exists() {
  local SOURCE="$1"
  local FILE="/etc/apt/sources.list"

  # 检查源是否已存在
  if ! grep -Fq "$SOURCE" "$FILE"; then
    backup_target "$FILE"
    echo "$SOURCE" | sudo tee -a "$FILE"
    echo "已添加源: $SOURCE"
  else
    echo "源已存在: $SOURCE"
  fi
}

deduplicate_sources_list() {
    local FILE="/etc/apt/sources.list"
    local tmp_file
    tmp_file=$(mktemp)
    backup_target "$FILE"

    awk '
        /^[[:space:]]*$/ { print; next }
        /^[[:space:]]*#/ { print; next }
        {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            if (!seen[$0]++) print
        }
    ' "$FILE" > "$tmp_file"
    sudo cp "$tmp_file" "$FILE"
    rm -f "$tmp_file"
}

repair_debian12_x86_network() {
    local distro_version
    distro_version=$(lsb_release -sr)

    if [ "$(uname -m)" != "x86_64" ] || [[ "$distro_version" != 12* ]]; then
        return 0
    fi

    echo "🛠️ 检测到 Debian 12 x86_64，执行网络兼容修复..."

    if dpkg -s systemd-resolved >/dev/null 2>&1; then
        backup_target "/etc/resolv.conf"
        sudo systemctl disable --now systemd-resolved >/dev/null 2>&1 || true

        if [ -L /etc/resolv.conf ]; then
            sudo rm -f /etc/resolv.conf
        fi

        sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 223.5.5.5
nameserver 8.8.8.8
options timeout:2 attempts:2
EOF
        echo "✅ 已恢复 /etc/resolv.conf 为静态 DNS，避免 systemd-resolved 接管导致断网。"
    fi

    backup_target "/etc/network/interfaces"
    if [ -f /etc/network/interfaces ]; then
        if ! grep -Eq '^\s*source\s+/etc/network/interfaces\.d/\*$' /etc/network/interfaces; then
            echo 'source /etc/network/interfaces.d/*' | sudo tee -a /etc/network/interfaces > /dev/null
        fi
    fi
}

install_systemd_resolved() {
    # 检查系统是否安装了 resolvconf
    if command -v resolvconf &> /dev/null; then
        echo "resolvconf is installed, modifying resolved.conf..."
        # 安装resolved
        apt install -y systemd-resolved

        # 创建 /etc/systemd/resolved.conf 的备份
        cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
        echo "Backup of /etc/systemd/resolved.conf created."

        # 修改 resolved.conf 配置
        cat <<EOF > /etc/systemd/resolved.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details
[Resolve]
DNS=1.1.1.1 8.8.8.8 114.114.114.114
FallbackDNS=1.0.0.1 114.114.115.115
DNSSEC=no
DNSOverTLS=no
DNSStubListener=no
#Domains=
#MulticastDNS=yes
#LLMNR=yes
#Cache=yes
#ReadEtcHosts=yes
#ResolveUnicastSingleLabel=no
EOF
        sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf 
        # 重启 systemd-resolved 服务
        systemctl restart systemd-resolved
        echo "systemd-resolved restarted with updated configuration."
        check_network
    else
        echo "resolvconf is not installed. Proceeding with normal installation of systemd-resolved."

        # 安装 systemd-resolved
        apt update
        apt install -y systemd-resolved
        echo "systemd-resolved installed."
    fi
}


# 根据传入的步骤执行不同的代码块
case "$RESTART_STEP" in
    0)
        # 第一次安装
        echo "正在执行第一次安装操作..."

        # 添加源
        # 获取系统发行版本代号
        OS_CODENAME=$(lsb_release -sc)

        # 添加官方源
        add_source_if_not_exists "deb http://deb.debian.org/debian/ ${OS_CODENAME} main contrib non-free"
        add_source_if_not_exists "deb http://deb.debian.org/debian/ ${OS_CODENAME}-updates main contrib non-free"
        add_source_if_not_exists "deb http://security.debian.org/debian-security ${OS_CODENAME}-security main contrib non-free"

        # 添加清华大学开源软件镜像站的源
        add_source_if_not_exists "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${OS_CODENAME} main contrib non-free"
        add_source_if_not_exists "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${OS_CODENAME}-updates main contrib non-free"
        add_source_if_not_exists "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${OS_CODENAME}-backports main contrib non-free"
        add_source_if_not_exists "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${OS_CODENAME}-security main contrib non-free"
        deduplicate_sources_list

        sudo apt update

        # 安装网络管理器
        sudo apt install -y network-manager

        # 配置 NetworkManager
        if [ ! -s /etc/NetworkManager/conf.d/100-disable-wifi-mac-randomization.conf ]; then
            backup_target "/etc/NetworkManager/conf.d/100-disable-wifi-mac-randomization.conf"
            cat << EOF | sudo tee /etc/NetworkManager/conf.d/100-disable-wifi-mac-randomization.conf
[connection]
wifi.mac-address-randomization=1

[device]
wifi.scan-rand-mac-address=no
EOF
        fi

        if [ ! -s /etc/NetworkManager/conf.d/99-ifupdown-managed.conf ]; then
            backup_target "/etc/NetworkManager/conf.d/99-ifupdown-managed.conf"
            cat << EOF | sudo tee /etc/NetworkManager/conf.d/99-ifupdown-managed.conf
[ifupdown]
managed=false
EOF
        fi

        repair_debian12_x86_network

        # 安装必要软件包
        # 必要的软件包列表
        NECESSARY_PACKAGES=(
            "apparmor-utils"
            "jq"
            "software-properties-common"
            "apt-transport-https"
            "avahi-daemon"
            "ca-certificates"
            "curl"
            "dbus"
            "socat"
            "bluez"
            "libtalloc2"
            "libwbclient0"
        )
        install_and_check "${NECESSARY_PACKAGES[@]}"
        
        echo "apparmor=1 security=apparmor" | sudo tee -a /boot/cmdline.txt
        # sudo apt install -y libtalloc2 libwbclient0

        # 安装其他必需包
        ADDITIONAL_PACKAGES=(
            "apparmor"
            "cifs-utils"
            "curl"
            "dbus"
            "jq"
            "libglib2.0-bin"
            "lsb-release"
            "network-manager"
            "nfs-common"
            "systemd-journal-remote"
            "udisks2"
            "wget"
            # "systemd-resolved"
        )
        install_and_check "${ADDITIONAL_PACKAGES[@]}"
        sudo apt-get --fix-broken install -y

        # 下载并安装 OS Agent
        os_agent_deb="$HA_DOWNLOAD_DIR/os-agent_1.3.0_linux.deb"
        download_with_retry "$OS_AGENT_REPOSITORY" "$os_agent_deb"
        install_deb_with_check "$os_agent_deb" || {
            echo "❌ OS Agent 安装失败，退出脚本。"
            exit 1
        }

        # 避免在 Debian 13 / x86 场景强制接管 DNS 导致断网
        if systemctl list-unit-files | grep -q '^systemd-resolved.service'; then
            echo "ℹ️ 检测到 systemd-resolved 服务，已避免强制启用；Debian 12 x86 将应用兼容修复。"
        else
            echo "ℹ️ 系统未提供 systemd-resolved，跳过安装与启用，避免网络配置被改写。"
        fi

        check_network

        # 重启
        echo "🎉 阶段 ${RESTART_STEP} 完成，系统即将重启进入下一阶段安装..."
        archive_logs single
        sudo reboot
        ;;
    1)
        # 第一次重启后
        echo "正在执行第一次重启后的操作..."
        # 检查 Docker 是否已安装
        if ! command -v docker &> /dev/null; then
            echo "Docker 未安装，请先安装 Docker 后再运行此脚本。"
            exit 1
        fi

        DOCKER_COMPOSE_FILE="docker-compose.yml"

        # 安装 Home Assistant 的 Docker 配置
        mkdir -p /home-assistant-config && cat <<EOF > ${DOCKER_COMPOSE_FILE}
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:2025.3
    volumes:
      - /home-assistant-config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    environment:
      - TZ=Asia/Shanghai
    privileged: true
    network_mode: host
    restart: unless-stopped
EOF
        # 检查文件是否生成成功
        if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
            echo "docker-compose.yml 文件生成失败，请检查写入权限。"
            exit 1
        fi

        echo "docker-compose.yml 文件已生成，使用的镜像地址为：ghcr.io/home-assistant/home-assistant:2025.3"

        # 启动 Docker 容器
        docker compose up -d

        # 调用容器检查和启动函数
        check_and_start_containers 0

        # 安装 HACS
        # 确保目标路径存在
        mkdir -p /home-assistant-config/custom_components/hacs

        # 定义下载目标路径
        hacs_zip="$HA_DOWNLOAD_DIR/hacs.zip"

        # 下载 HACS
        download_with_retry "$HACS_REPOSITORY" "$hacs_zip"

        # 解压缩 HACS 到目标路径
        unzip "$hacs_zip" -d /home-assistant-config/custom_components/hacs

        # 回到主目录
        cd ~
        # 安装homeassistant-supervised前置依赖
        sudo apt install -y \
        avahi-daemon \
        ca-certificates \
        socat \
        pulseaudio
        sudo apt install systemd-journal-remote bluez cifs-utils nfs-common -y
        # 第一次检查
        sudo apt --fix-broken install -y

        # homeassistant-supervised必备的软件包列表
        PACKAGES=(
            "network-manager"
            "apparmor-utils"
            "jq"
            "software-properties-common"
            "apt-transport-https"
            "avahi-daemon"
            "ca-certificates"
            "curl"
            "dbus"
            "socat"
            "bluez"
            "libtalloc2"
            "libwbclient0"
            "apparmor"
            "cifs-utils"
            "libglib2.0-bin"
            "lsb-release"
            "nfs-common"
            "systemd-journal-remote"
            "udisks2"
            "pulseaudio"
        )

        # 调用函数，0-当前调用次数
        check_and_install_packages 0 "${PACKAGES[@]}"

        # 第二次检查
        sudo apt-get --fix-broken install -y

        # 安装 Home Assistant Supervised
        homeassistant_supervised_deb="$HA_DOWNLOAD_DIR/homeassistant-supervised.deb"
        download_with_retry "$SUPERVISED_REPOSITORY" "$homeassistant_supervised_deb"
        install_deb_with_check "$homeassistant_supervised_deb" || {
            echo "❌ Home Assistant Supervised 安装失败，退出脚本。"
            exit 1
        }


        # 第三次检查
        sudo apt --fix-broken install -y
        sudo systemctl enable hassio-supervisor

        # 重启系统
        echo "🎉 阶段 ${RESTART_STEP} 完成，系统即将重启进入下一阶段安装..."
        archive_logs single
        sudo reboot
        ;;

    2)
        # 第二次重启后
        echo "正在执行第二次重启后的操作..."

        # 定义需要监控的容器列表
        containers=("homeassistant" "hassio_multicast" "hassio_observer" "hassio_audio" "hassio_dns" "hassio_cli" "hassio_supervisor")
        echo "正在监控Docker容器启动状况，等待所有容器启动完成..."

        # 最大监控时间（单位：秒）
        MAX_MONITOR_TIME=1200  # 20分钟
        start_time=$(date +%s)

        while true; do
            echo -e "======== $(date) ========\n"
            all_started=true
            not_started=()

            # 检查容器状态
            for container in "${containers[@]}"; do
                if docker ps --filter "name=$container" --format '{{.Names}}' | grep -q "$container"; then
                    echo "$container is running."
                else
                    echo "$container is not started yet."
                    all_started=false
                    not_started+=("$container")
                fi
            done

            # 如果所有容器启动成功，退出循环
            if $all_started; then
                echo "所有容器已启动！"
                break
            fi

            # 检查是否超时
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))

            if [ $elapsed_time -ge $MAX_MONITOR_TIME ]; then
                echo "监控已超时（超过20分钟）。以下容器尚未启动："
                for container in "${not_started[@]}"; do
                    echo "- $container"
                done

                if prompt_yes_no "监控已超时，是否需要继续监控20分钟？"; then
                    echo "继续监控容器状态..."
                    start_time=$(date +%s)  # 重置监控开始时间
                else
                    echo "用户选择停止监控，退出脚本。"
                    exit 0
                fi
            fi


            # 等待5秒后继续检查
            sleep 5
        done
        # 解决Home Assistant Supervisor 的 unhealthy检查错误
        CONTAINER_NAME="hassio_cli"

        # 检查容器是否运行
        # 检查容器是否运行
        if sudo docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            echo "容器 ${CONTAINER_NAME} 正在运行。"
            
            # 询问用户是否需要关闭健康检查
            if prompt_yes_no "是否需要关闭健康检查命令？"; then
                echo "正在执行忽略健康检查的命令..."
                if sudo docker exec "${CONTAINER_NAME}" ha jobs options --ignore-conditions healthy; then
                    echo "命令执行成功。"
                else
                    echo "命令执行失败，请检查容器状态和日志。"
                    echo "您可以手动运行以下命令以尝试修复："
                    echo "sudo docker exec ${CONTAINER_NAME} ha jobs options --ignore-conditions healthy"
                fi
            else
                echo "跳过关闭健康检查命令。"
            fi
        else
            # 如果容器未启动
            echo "容器 ${CONTAINER_NAME} 未启动，无法修复健康检查问题。"
            echo "请先启动容器 ${CONTAINER_NAME} 后再执行以下命令："
            echo
            echo "sudo docker exec \"${CONTAINER_NAME}\" ha jobs options --ignore-conditions healthy"
            echo
        fi


        # 安装 HACS 配置项
        echo "现在可以选择是否先初始化 Home Assistant 或直接安装 HACS 加载项。"
        echo "无论哪种方式，HACS 加载项都将在 Home Assistant 初始化后生效，并且需要重启 Home Assistant 才能加载 HACS。"

        # 获取当前设备的局域网IP地址，取出第一个以192开头的IP地址
        LOCAL_IP=$(hostname -I | awk '{for(i=1;i<=NF;i++) if($i ~ /^192\./) print $i}' | head -n 1)

        # 检查是否能成功获取到IP地址
        if [ -z "$LOCAL_IP" ]; then
            echo "无法获取到设备的局域网IP地址。"
            echo "请手动访问设备所在局域网的 8123（Home Assistant默认)端口进行初始化。例如：http://<device-ip>:8123"
        else
            echo "设备的局域网IP地址为: $LOCAL_IP"
            echo "请在浏览器中访问 http://$LOCAL_IP:8123 （这个地址可能是参考的）进行 Home Assistant 的初始化。"
        fi

        echo "准备安装 HACS 加载项，请按任意键继续..."
        read -n 1 -s -r
        echo "开始安装 HACS 配置项"

        cd /usr/share/hassio/homeassistant || {
            echo "❌ 进入 Home Assistant 安装目录失败，请检查路径是否存在。"
            exit 1
        }
        mkdir -p custom_components/hacs
        cd custom_components/hacs

        # 下载并解压 HACS
        download_with_retry "$HACS_REPOSITORY" "hacs.zip"
        unzip "$HA_DOWNLOAD_DIR/hacs.zip" -d .

        # 返回初始工作目录
        cd "$INITIAL_DIR" || {
            echo "❌ 返回初始工作目录失败：$INITIAL_DIR"
            exit 1
        }

        # 日志目录清理
        if [ -d "$LOG_DIR" ] && [ "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
            archive_logs all
            echo "✅ 删除日志目录：$LOG_DIR"
            # 避免清理 rm -rf /
            if [[ "$LOG_DIR" == "/" || "$LOG_DIR" == "" ]]; then
                echo "❌ 日志目录路径无效，跳过清理。"
                exit 1
            fi
            rm -rf "$LOG_DIR"
        else
            echo "ℹ️ 日志目录已空或不存在，无需清理。"
        fi

        # 清理下载目录
        if [ -d "$HA_DOWNLOAD_DIR" ] && [ "$(ls -A "$HA_DOWNLOAD_DIR")" ]; then
            echo "🧹 清理下载目录：$HA_DOWNLOAD_DIR"
            # 避免清理 rm -rf /
            if [[ "$HA_DOWNLOAD_DIR" == "/" || "$HA_DOWNLOAD_DIR" == "" ]]; then
                echo "❌ 下载目录路径无效，跳过清理。"
                exit 1
            fi
            rm -rf "$HA_DOWNLOAD_DIR"/*
            echo "✅ 下载目录已清理完成。"
        else
            echo "ℹ️ 下载目录为空，无需清理。"
        fi


        # 第三阶段完成
        echo "🎉HACS 安装完成！快去 $LOCAL_IP:8123 使用 Home Assistant 吧! 重启 Home Assistant 即可添加 HACS 加载项。无需重启系统"

        ;;
    3) 
        echo "正在归档日志目录中的所有日志文件..."

        # 确保日志目录存在
        if [ ! -d "$LOG_DIR" ]; then
            echo "日志目录不存在：$LOG_DIR"
            exit 1
        fi

        # 关闭日志输出流（停止日志写入）
        exec > /dev/tty 2>&1

        # 打包日志文件，忽略文件变化警告
        ARCHIVE_NAME="logs_${TIMESTAMP}.tar.gz"
        tar --warning=no-file-changed -czvf "$ARCHIVE_NAME" -C "$LOG_DIR" .

        # 输出日志包存放位置
        echo "日志已成功打包。"
        echo "日志存放位置：$(pwd)/$ARCHIVE_NAME"

        # 退出脚本
        exit 0
        ;;
    *)
        # 处理无效输入
        echo "无效的参数，请传入 0、1 或 2 来指定操作步骤。"
        exit 1
        ;;
esac
