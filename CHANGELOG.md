# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

------

## [v1.2] - 2024-11-24

### Added

- Three-step installation process

  :

  - **Step 0**: Initial installation (basic system setup and dependencies installation).
  - **Step 1**: Post-first reboot installation (Docker and HACS setup).
  - **Step 2**: Post-second reboot finalization (Home Assistant container and system monitoring setup).

- **Automatic reboot prompts** after Steps 0 and 1 for a seamless installation flow.

### Improved

- Log recording and archival:
  - All installation outputs are redirected to stage-specific log files.
  - Logs are automatically archived into a `.tar.gz` file after the final installation step for easy debugging and sharing.

### Supported

- Compatible with **Debian Bullseye (11)** on RK3318 devices.
- **Home Assistant Supervisor** and **HACS** are fully supported.
- NetworkManager configuration enhancements to ensure stable network performance.

------

## [v1.1] - 2024-11-20

### Added

- Initial implementation of the installation script for Home Assistant on RK3318 devices.
- Basic Home Assistant installation steps.
- Initial compatibility with Debian Bullseye (11).

------

## [v1.2] - 2024-11-24

### Improved

- Add new package installation integrity check

------



## [v1.3] - 2025-01-05

### Added

- After the installation is complete, add [the option to turn off security checking for Home Assistant Supervisor], 

  > Otherwise you will get a HACS alter that the system is unhealthy.

------



## Future Plans

- Add support for other Debian versions.
- Provide better error handling for unsupported systems.
- Implement additional automated configuration features for Home Assistant.

------

### How to Use

Visit the [Releases](https://github.com/CaixyPromise/rk3318-homeassistant-installer/releases) page to download the latest version of the script.

