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

1. **Download the script**:

   ```bash
   wget https://raw.githubusercontent.com/CaixyPromise/rk3318-homeassistant-installer/main/src/install_homeAssistant.sh -O install_homeAssistant.sh
   chmod +x install_homeAssistant.sh
   ```

2. **Execute installation stages**: Follow the staged installation steps below. After each stage, **reboot your system** and continue with the next step.

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

3. **Access Home Assistant**:

   - Open your browser and visit:

     ```
     http://<device-ip>:8123
     ```

   Replace `<device-ip>` with your device's local network IP.

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