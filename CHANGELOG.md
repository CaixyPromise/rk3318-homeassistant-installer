# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/) (with optional pre-release tags such as `-beta` when appropriate).

------

## [v1.5-beta] - 2025-11-24

### Added

- **Global error collection and exit summary**
  - Introduced a centralized error collection system that records all issues during script execution and prints an **Installation Issues Summary** on exit, including suggested manual commands to fix common problems.
- **Step 2 pre-flight environment check**
  - Added `precheck_step2_environment` to verify that steps `0` and `1` completed successfully before running step `2`, checking core packages, OS Agent, Home Assistant Supervised, Docker/Compose, `hassio-supervisor` service, key directories, and the `homeassistant` container.

### Improved

- **Logging and archiving robustness**
  - Refined log archiving to produce per-stage archives with human-readable details (archive path, size, and timestamp), and ensured logs are safely archived before final cleanup at the end of step `2`.
- **Download directory handling**
  - Fixed and unified the use of the global download directory for all downloads, and enhanced download output to include target paths and file sizes.
- **Docker and environment diagnostics**
  - Strengthened Docker and `docker compose` checks in steps `1` and `2`, including automatic attempts to start services and clear guidance when manual intervention is required (e.g., installing `docker.io` / `docker-compose-plugin`, checking systemd status and logs).

### Update
- **Fixed Home Assistant container image version**
  - The Home Assistant container image version is fixed at 2025.3.

### Fixed

- **Path and installation edge cases**
  - Resolved several issues in the package auto-install and download utilities, including incorrect path handling and missing `.deb` detection, reducing the likelihood of silent failures between installation stages.

------

## [v1.4] - 2025-01-19

### Added

- **Expanded Operating System Support** :star:
  - **Added compatibility for Debian Bookworm (12)** alongside Debian Bullseye (11), providing users with more flexibility in their installation environment.

- **Enhanced Architecture Support** :star:
  - Included support for additional architectures such as **armv7, armv5, and i386,** broadening the range of compatible devices.

- **Home Assistant Supervisor Health Check Option**
  - Introduced an option to disable health checks for Home Assistant Supervisor, preventing HACS from marking the system as unhealthy and enhancing system stability.

### Improved

- **Reliable Download Mechanism**
  - Enhanced the download process with robust retry logic and user prompts to ensure successful file downloads, reducing the likelihood of installation interruptions.

- **Comprehensive Logging and Archiving**
  - Implemented stage-specific log files and an improved log archival system, facilitating easier debugging and streamlined issue resolution.

- **Advanced Container Management**
  - Improved Docker container monitoring with more accurate startup checks and automated restart attempts, ensuring all necessary containers are running correctly.

- **Safe Cleanup Procedures**
  - Refined the cleanup logic for log and download directories to safely archive logs before deletion, preventing accidental loss of important log data.

------

## [v1.3] - 2025-01-05

### Added

- After the installation is complete, add [the option to turn off security checking for Home Assistant Supervisor], 

  > Otherwise you will get a HACS alter that the system is unhealthy.

------



## [v1.2] - 2024-11-24

### Added

- Three-step installation process:

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
- Network Manager configuration enhancements to ensure stable network performance.

### Improved

- Add new package installation integrity check

------



## [v1.1] - 2024-11-20

### Added

- Initial implementation of the installation script for Home Assistant on RK3318 devices.
- Basic Home Assistant installation steps.
- Initial compatibility with Debian Bullseye (11).

------



## Future Plans

- Modularization and Code Decoupling: Refactor Code Structure.
- Enhanced Automation and Usability: End-to-End Automation, Interactive Installer Mode.
- Provide better error handling for unsupported systems.
- Implement additional automated configuration features for Home Assistant.

------

### How to Use

Visit the [Releases](https://github.com/CaixyPromise/rk3318-homeassistant-installer/releases) page to download the latest version of the script.

