# rk3318-homeassistant-installer

[简体中文](README_CN.md) | [English](#README.md)

### 项目简介

`rk3318-homeassistant-installer` 是一个针对 **Debian Bullseye (11)** 的 Shell 脚本，用于在 RK3318 设备上安装 **Home Assistant**、**Home Assistant Supervisor** 和 **HACS**。

------

### 功能特点

- 安装分为 **三个阶段**，每个阶段都有明确的日志。
- 支持 **Home Assistant Supervisor** 和 **HACS**。
- 自动化安装，操作简单。
- 新增支持 **Debian 12 (Bookworm)**（测试模式）。
- 兼容 **ARM (aarch64, armv7, armv5)** 和 **AMD64 (x86_64)** 架构。

------

### 前置条件

1. 系统需运行 **Debian Bullseye (11)**。

2. 使用以下命令确认系统版本：

   ```bash
   lsb_release -sc
   ```

   输出应为 

   ```
   bullseye
   ```
   
   或
   
   ```
   bookworm
   ```

------

### 安装步骤

#### 方法一：使用 Git

1. **克隆代码仓库：**确保已安装 **Git**。若未安装，请运行以下命令进行安装：

```sh
sudo apt update && sudo apt install -y git
```

安装完成后，请重新执行此步骤。

2. 克隆代码仓库：

```sh
git clone https://github.com/CaixyPromise/rk3318-homeassistant-installer.git
cd rk3318-homeassistant-installer/src
chmod +x install_homeAssistant.sh
```

#### 方法二：直接下载

1. **下载脚本**：

   ```bash
   wget https://raw.githubusercontent.com/CaixyPromise/rk3318-homeassistant-installer/main/src/install_homeAssistant.sh -O install_homeAssistant.sh
   chmod +x install_homeAssistant.sh
   ```

### 执行代码

**执行安装阶段**：确保你已经下载完成代码并进入代码目录：

```sh
ls
```

**:warning: 注意：你必须看到以下文字才能开始安装。**

```
./install_homeAssistant.sh
```

安装分为以下三阶段。每个阶段完成后需要 **重启系统** 并继续下一阶段。

- **阶段一：初始安装**：

  ```bash
  sudo ./install_homeAssistant.sh 0
  ```

  执行系统基础配置和依赖安装。根据提示完成操作并重启。

- **阶段二：第一次重启后**：

  ```bash
  sudo ./install_homeAssistant.sh 1
  ```

  安装 Docker 配置和 HACS，完成后重启。

- **阶段三：第二次重启后**：

  ```bash
  sudo ./install_homeAssistant.sh 2
  ```

  启动 Home Assistant 容器并完成配置。

- **一键回滚（新增）**：

  ```bash
  sudo ./install_homeAssistant.sh rollback
  ```

  脚本现在会在关键文件修改前，将备份写入 `ha_backups/<时间戳>/`（如 APT 源与 NetworkManager 配置）。若阶段 0 网络异常，可执行回滚恢复最近一次备份。

- **x86 / Debian 12 网络处理（新增）**：

  阶段 0 现在不再通过禁用 `systemd-resolved` 或继续依赖 `ifupdown` 来“保底联网”。针对 Debian 12 x86，脚本会按 Home Assistant Supervised 官方要求，把默认有线网卡从 `ifupdown` 迁移到 `NetworkManager`，同时启用 `systemd-resolved`。这样修复的是根因：旧逻辑让 `ifupdown`、`NetworkManager`、`systemd-resolved` 同时参与网络控制，导致“IP 和默认路由都正常，但 DNS 失效”。
  
- **访问 Home Assistant**：

   - 打开浏览器并访问：

     ```
     http://<设备IP>:8123
     ```

   将 `<设备IP>` 替换为设备局域网 IP。

- 日志打包

   - 使用以下命令输出打包（已经启动过脚本且日志目录存在）

     ```shell
     sudo ./install_homeAssistant.sh 4
     ```

------

### 日志记录和调试

1. 每个阶段都会自动保存日志文件。
2. 安装完成后，日志文件会被打包成 `.tar.gz` 格式，位于脚本文件夹的 `logs` 目录中。

------

### 如何贡献

💡 欢迎通过 [问题反馈](https://github.com/CaixyPromise/rk3318-homeassistant-installer/issues) 和 [Pull Request](https://github.com/CaixyPromise/rk3318-homeassistant-installer/pulls) 参与贡献。

------

### 支持项目

🌟 **在 GitHub 上为此项目加星**，支持开发并获取最新功能版本动态！

### 许可证信息

本项目采用 **MIT 许可证**。有关详情，请参阅 [LICENSE](LICENSE) 文件。
