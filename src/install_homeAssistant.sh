#!/bin/bash
# ============================================================
# Project: rk3318-homeassistant-installer
# Author: CAIXYPROMISE
# Version: 1.2
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
echo "Version: 1.2"
echo "Last modified: 2024-11-24"
echo "Supported OS: Debian Bullseye (11)"
echo "=========================================="
echo "💡 Tip: Star this project on GitHub to get updates and new features!"
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
SUPERVISED_REPOSITORY=https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb

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
if [ -z "$RESTART_STEP " ]; then
    echo "请提供一个参数：0（第一次安装），1（第一次重启后），2（第二次重启后）"
    exit 1
fi

# 日志文件名
LOG_FILE="$LOG_DIR/${TIMESTAMP}_stage_${RESTART_STEP }.log"

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
        sudo apt install -y apparmor-utils jq software-properties-common apt-transport-https avahi-daemon ca-certificates curl dbus socat
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


        # 安装 Home Assistant Supervised
        download_with_retry $SUPERVISED_REPOSITORY "homeassistant-supervised.deb"
        sudo dpkg -i homeassistant-supervised.deb
        # 第二次检查
        sudo apt --fix-broken install -y

        # 重启系统
        echo "第二阶段完成：请将系统重启，进入第三阶段安装..."
        sudo reboot
        ;;

    2)
        # 第二次重启后
        echo "正在执行第二次重启后的操作..."

        # 监控 Home Assistant 容器的启动情况
        containers=("homeassistant" "hassio_multicast" "hassio_observer" "hassio_audio" "hassio_dns" "hassio_cli" "hassio_supervisor")
        echo "正在监控Docker容器启动状况，等待所有容器启动完成"
        while true; do
            echo -e "======== $(date) ========\n"
            all_started=true
            for container in "${containers[@]}"; do
                if docker ps --filter "name=$container" --format '{{.Names}}' | grep -q "$container"; then
                    echo "$container is running."
                else
                    echo "$container is not started yet."
                    all_started=false
                fi
            done

            if $all_started; then
                echo "All containers are started."
                break
            fi
            sleep 5
        done

        # 安装 HACS 配置项
        echo "现在可以选择是否先初始化 Home Assistant 或直接安装 HACS 加载项。"
        echo "无论哪种方式，HACS 加载项都将在 Home Assistant 初始化后生效，并且需要重启 Home Assistant 才能加载 HACS。"

        # 获取当前设备的局域网IP地址，取出第一个以192开头的IP地址
        LOCAL_IP=$(hostname -I | awk '{for(i=1;i<=NF;i++) if($i ~ /^192\./) print $i}' | head -n 1)

        # 检查是否能成功获取到IP地址
        if [ -z "$LOCAL_IP" ]; then
            echo "无法获取到设备的局域网IP地址。"
            echo "请手动访问设备所在局域网的 8123 端口进行初始化。例如：http://<device-ip>:8123"
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

    *)
        # 处理无效输入
        echo "无效的参数，请传入 0、1 或 2 来指定操作步骤。"
        exit 1
        ;;
esac

# 打包日志
tar -czvf "$LOG_DIR/logs_${TIMESTAMP}.tar.gz" "$LOG_DIR"
echo "日志打包完成：$LOG_DIR/logs_${TIMESTAMP}.tar.gz