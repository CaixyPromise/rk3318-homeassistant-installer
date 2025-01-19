# rk3318-homeassistant-installer

[简体中文](README_CN.md) | [English](#README.md)

------

## English Instructions

### Project Overview

`rk3318-homeassistant-installer` is a shell script designed to install **Home Assistant**, **Home Assistant Supervisor**, and **HACS** on RK3318 devices running **Debian Bullseye (11)**.

------

### Features

- Automated installation in **three stages**.
- Supports **Home Assistant Supervisor** and **HACS**.
- Clear logs for each installation stage.
- Now supports **Debian 12 (Bookworm)** in testing mode. 
- Compatible with **ARM (aarch64, armv7, armv5)** and **AMD64 (x86_64)** architectures.

------

### Prerequisites

1. Ensure your system is running **Debian Bullseye (11)**.

2. Use the following command to confirm your Debian version:

   ```bash
   lsb_release -sc
   ```

   The output should be 

   ```
   bullseye
   ```

   .

------

### Installation Instructions

#### Option 1: Using Git

1. Make sure **Git** is installed. If Git is not installed, run the following command:

```sh
sudo apt update && sudo apt install -y git
```

After Git is successfully installed, proceed to step 2.

2. Clone the repository:

```shell
git clone https://github.com/CaixyPromise/rk3318-homeassistant-installer.git
cd rk3318-homeassistant-installer/src
chmod +x install_homeAssistant.sh
```

If Git is not installed, run the following step 1 and repeat.

#### Option 2: Direct Download

1. **Download the script**:

   ```bash
   wget https://raw.githubusercontent.com/CaixyPromise/rk3318-homeassistant-installer/main/src/install_homeAssistant.sh -O install_homeAssistant.sh
   chmod +x install_homeAssistant.sh
   ```

### Execute the Script

**Execute installation stages**: **After the script has been downloaded and you are in the download directory**：

```sh
ls
```

**:warning: CAUTION: You are required to see the following text to start the installation.**

Follow the staged installation steps below. After each stage, **reboot your system** and continue with the next step.

- **Stage 1: Initial Installation**:

  ```bash
  sudo ./install_homeAssistant.sh 0
  ```

  Installs basic system settings and dependencies. Follow the prompts to reboot.

- **Stage 2: After First Reboot**:

  ```bash
  sudo ./install_homeAssistant.sh 1
  ```

  Sets up Docker configuration and HACS. Reboot when prompted.

- **Stage 3: Final Installation**:

  ```bash
  sudo ./install_homeAssistant.sh 2
  ```

  Starts Home Assistant containers and finalizes the setup.
  
- **Access Home Assistant**:

   - Open your browser and visit:

     ```
     http://<device-ip>:8123
     ```

   Replace `<device-ip>` with your device's local network IP.

- **Log archive**:

   - Use the below command to archive the log.(runtime output)

     ```shell
     sudo ./install_homeAssistant.sh 3
     ```

------

### Logs and Debugging

1. Logs for each stage are saved automatically.
2. After the installation is complete, logs are archived into a `.tar.gz` file located in the `logs` directory of the script's folder.

-----

### Contributing

💡 Feel free to contribute via [Issues](https://github.com/CaixyPromise/rk3318-homeassistant-installer/issues) and [Pull Requests](https://github.com/CaixyPromise/rk3318-homeassistant-installer/pulls).

### Support the Project

🌟 **Star this repository on GitHub** to support development and get updates on new features!

### License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.