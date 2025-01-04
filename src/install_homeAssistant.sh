#!/bin/bash
# ============================================================
# Project: rk3318-homeassistant-installer
# Author: CAIXYPROMISE
# Version: 1.3
# Last Modified: 2024-11-24
# GitHub Repository: https://github.com/CaixyPromise/rk3318-homeassistant-installer
# 
# Copyright (c) 2024 CAIXYPROMISE
#
# This script is licensed under the MIT License. 
# You may obtain a copy of the License at https://opensource.org/licenses/MIT
# Supported Operating Systems:
# - Debian Bullseye (11)
# A
# ============================================================
echo "=========================================="
echo "rk3318-homeassistant-installer"
echo "Author: CAIXYPROMISE"
echo "License: MIT"
echo "GitHub repository: https://github.com/CaixyPromise/rk3318-homeassistant-installer"
echo "Version: 1.3"
echo "Last modified: 2025-01-05"
echo "Supported OS: Debian Bullseye (11)"
echo "=========================================="
echo "💡 Tip: ⭐Star this project on GitHub to get updates and new features!"
echo "👉 Visit: https://github.com/CaixyPromise/rk3318-homeassistant-installer"
echo "=========================================="

OS_CODENAME=$(lsb_release -sc)  
if [[ "$OS_CODENAME" != "bullseye" ]]; then
    echo "Error: This script is currently designed for Debian Bullseye systems only."
    echo "Your system is detected as: $OS_CODENAME"
    echo "Exiting the script."
    exit 1
fi
echo "System detected as Debian Bullseye. Proceeding with the installation..."
HACS_REPOSITORY=https://github.com/hacs/integration/releases/download/2.0.1/hacs.zip
OS_AGENT_REPOSITORY=https://github.com/home-assistant/os-agent/releases/download/1.3.0/os-agent_1.3.0_linux_aarch64.deb
SUPERVISED_REPOSITORY=https://github.com/home-assistant/supervised-installer/releases/download/1.8.0/homeassistant-supervised.deb

# 创建日志目录
LOG_DIR="$(pwd)/logs"
mkdir -p $LOG_DIR

# 获取当前时间
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 打印操作系统信息
OS_INFO=$(uname -a)
echo "操作系统信息: $OS_INFO"

# 检查传入的参数 (重启次数)
RESTART_STEP=$1

# 如果没有传入参数，提示用户输入
if [ -z "$RESTART_STEP" ]; then
    echo "请提供一个参数：0（第一次安装），1（第一次重启后），2（第二次重启后）"
    exit 1
fi

# 日志文件名
LOG_FILE="$LOG_DIR/${TIMESTAMP}_stage_${RESTART_STEP}.log"

# 重定向所有输出到日志文件
exec > >(tee -a "$LOG_FILE") 2>&1

download_with_retry() {
    URL=$1
    DEST=$2
    MAX_RETRIES=3
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo "尝试下载: $URL ..."
        wget $URL -O $DEST
        if [ $? -eq 0 ]; then
            echo "下载成功: $DEST"
            return 0
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            echo "下载失败，正在重试 ($RETRY_COUNT/$MAX_RETRIES)..."
            sleep 5  # 等待 5 秒后重试
        fi
    done

    echo "下载失败 $MAX_RETRIES 次，请检查网络连接并手动重试。"
    echo "按任意键重新尝试下载..."
    read -n 1 -s -r
    download_with_retry $URL $DEST  # 递归重试，直到成功
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
            echo "$package 未安装或安装失败"
            missing_packages+=("$package")
        else
            echo "$package 已安装"
        fi
    done

    # 如果有未安装的软件包
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "需要重新安装以下未安装的软件包: ${missing_packages[*]}"

        # 更新包索引并安装
        sudo apt-get update
        sudo apt-get install -y "${missing_packages[@]}"

        # 检查修复依赖问题
        sudo apt-get --fix-broken install -y

        # 递归检查和安装
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "重新检查安装状态，当前重试次数：$((retry_count + 1))"
            check_and_install_packages $((retry_count + 1)) "${packages[@]}"
        else
            echo "超出最大重试次数 ($MAX_RETRIES)。退出脚本。"
            echo "需要重新安装以下未安装的软件包: ${missing_packages[*]}"
            exit 1
        fi
    else
        echo "所有软件包都已成功安装，无需进一步操作。"
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

# 根据传入的步骤执行不同的代码块
case "$RESTART_STEP" in
    0)
        # 第一次安装
        echo "正在执行第一次安装操作..."

        # 添加源
        echo "deb http://deb.debian.org/debian/ bullseye main contrib non-free" | sudo tee -a /etc/apt/sources.list
        echo "deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free" | sudo tee -a /etc/apt/sources.list
        echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" | sudo tee -a /etc/apt/sources.list
        sudo apt update

        # 安装网络管理器
        sudo apt install -y network-manager

        # 配置 NetworkManager
        if [ ! -s /etc/NetworkManager/conf.d/100-disable-wifi-mac-randomization.conf ]; then
            cat << EOF | sudo tee /etc/NetworkManager/conf.d/100-disable-wifi-mac-randomization.conf
[connection]
wifi.mac-address-randomization=1

[device]
wifi.scan-rand-mac-address=no
EOF
        fi

        # 安装必要软件包
        sudo apt install -y apparmor-utils jq software-properties-common apt-transport-https avahi-daemon ca-certificates curl dbus socat bluez
        echo "apparmor=1 security=apparmor" | sudo tee -a /boot/cmdline.txt
        sudo apt install -y libtalloc2 libwbclient0

        # 安装其他必需包
        sudo apt install -y apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote udisks2 wget

        # 下载并安装 OS Agent
        download_with_retry $OS_AGENT_REPOSITORY "os-agent_1.3.0_linux_aarch64.deb"
        sudo dpkg -i os-agent_1.3.0_linux_aarch64.deb

        # 启用并启动 systemd-resolved 服务
        sudo systemctl enable systemd-resolved
        sudo systemctl start systemd-resolved
        if ! systemctl is-active --quiet systemd-resolved; then
            echo "systemd-resolved 服务启动失败，退出脚本运行, 考虑重新当前阶段的脚本? 当前阶段为: $RESTART_STEP"
            exit 1
        else
            echo "systemd-resolved 服务启动成功"
        fi

        # 重启
        echo "第一阶段完成：请将系统重启，以进入第二阶段安装..."
        sudo reboot
        ;;

    1)
        # 第一次重启后
        echo "正在执行第一次重启后的操作..."

        # 安装 Home Assistant 的 Docker 配置
        mkdir -p /home-assistant-config && cat <<EOF > docker-compose.yml
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
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

        # 启动 Docker 容器
        docker compose up -d
        # 调用容器检查和启动函数
        check_and_start_containers 0

        # 安装 HACS
        cd /home-assistant-config
        mkdir custom_components && cd custom_components && mkdir hacs
        download_with_retry $HACS_REPOSITORY "hacs.zip"
        mv ./hacs.zip ./hacs
        cd hacs && unzip hacs.zip
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
        download_with_retry $SUPERVISED_REPOSITORY "homeassistant-supervised.deb"
        sudo dpkg -i homeassistant-supervised.deb
        # 第三次检查
        sudo apt --fix-broken install -y
        sudo systemctl enable hassio-supervisor

        # 重启系统
        echo "第二阶段完成：请将系统重启，进入第三阶段安装..."
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

                # 提示用户选择是否继续监控
                while true; do
                    read -p "是否需要继续监控20分钟？(Y(y)/N(n)): " continue_monitoring
                    case $continue_monitoring in
                        [Yy]* )
                            echo "继续监控容器状态..."
                            start_time=$(date +%s)  # 重置监控开始时间
                            break
                            ;;
                        [Nn]* )
                            while true; do
                                read -p "是否需要继续下一步操作？(Y(y)/N(n)): " proceed_next
                                case $proceed_next in
                                    [Yy]* )
                                        echo "继续下一步操作..."
                                        break 2  # 跳出内外层循环，进入下一步
                                        ;;
                                    [Nn]* )
                                        echo "退出脚本。"
                                        exit 0
                                        ;;
                                    * )
                                        echo "请输入有效选项：Y(y) 或 N(n)。"
                                        ;;
                                esac
                            done
                            ;;
                        * )
                            echo "请输入有效选项：Y(y) 或 N(n)。"
                            ;;
                    esac
                done
            fi

            # 等待5秒后继续检查
            sleep 5
        done
        # 解决Home Assistant Supervisor 的 unhealthy检查错误
        CONTAINER_NAME="hassio_cli"

        if sudo docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            # 如果容器正在运行，执行忽略健康检查的命令
            echo "容器 ${CONTAINER_NAME} 正在运行，正在执行忽略健康检查的命令..."
            sudo docker exec ${CONTAINER_NAME} ha jobs options --ignore-conditions healthy
            if [ $? -eq 0 ]; then
                echo "命令执行成功。"
            else
                echo "命令执行失败，请检查日志。"
            fi
        else
            # 如果容器未启动，提示用户
            echo "容器 ${CONTAINER_NAME} 未启动，无法修复健康检查问题。"
            echo "请先启动容器 ${CONTAINER_NAME} 后再执行以下命令："
            echo
            echo "sudo docker exec ${CONTAINER_NAME} ha jobs options --ignore-conditions healthy"
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


        cd /usr/share/hassio/homeassistant
        mkdir custom_components && cd custom_components && mkdir hacs
        download_with_retry $HACS_REPOSITORY "hacs.zip"
        mv ./hacs.zip ./hacs
        cd hacs && unzip hacs.zip
        cd ~

        echo "HACS 安装完成！快去$LOCAL_IP:8123 使用Home Assistant吧! 重启Home Assistant即可添加HACS加载项。无需重启系统"
        ;;
    3) 
        echo "正在归档日志目录中的所有日志文件..."

        # 确保日志目录存在
        if [ ! -d "$LOG_DIR" ]; then
            echo "日志目录不存在：$LOG_DIR"
            exit 1
        fi

        # 打包日志文件
        ARCHIVE_NAME="logs_${TIMESTAMP}.tar.gz"
        tar -czvf "$ARCHIVE_NAME" -C "$LOG_DIR" .

        # 输出日志包存放位置
        echo "日志已成功打包。"
        echo "日志存放位置：$(pwd)/$ARCHIVE_NAME"
        ;;
    *)
        # 处理无效输入
        echo "无效的参数，请传入 0、1 或 2 来指定操作步骤。"
        exit 1
        ;;
esac

# 打包日志
tar -czvf "$LOG_DIR/logs_${TIMESTAMP}.tar.gz" "$LOG_DIR"
echo "日志打包完成：$LOG_DIR/logs_${TIMESTAMP}.tar.gz
