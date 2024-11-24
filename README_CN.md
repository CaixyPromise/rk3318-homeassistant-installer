# rk3318-homeassistant-installer

[简体中文](README_CN.md) | [English](#README.md)

### 项目简介

`rk3318-homeassistant-installer` 是一个针对 **Debian Bullseye (11)** 的 Shell 脚本，用于在 RK3318 设备上安装 **Home Assistant**、**Home Assistant Supervisor** 和 **HACS**。

------

### 功能特点

- 安装分为 **三个阶段**，每个阶段都有明确的日志。
- 支持 **Home Assistant Supervisor** 和 **HACS**。
- 自动化安装，操作简单。

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

------

### 安装步骤

1. **下载脚本**：

   ```bash
   wget https://raw.githubusercontent.com/CaixyPromise/rk3318-homeassistant-installer/main/install.sh -O install_homeAssistant.sh
   chmod +x install_homeAssistant.sh
   ```

2. **执行安装阶段**： 安装分为以下三阶段。每个阶段完成后需要 **重启系统** 并继续下一阶段。

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

3. **访问 Home Assistant**：

   - 打开浏览器并访问：

     ```
     http://<设备IP>:8123
     ```

   将 `<设备IP>` 替换为的设备局域网 IP。

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