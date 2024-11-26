<h1>DirSentinel - Bash-based, Real-time Directory Monitoring and Logging</h1>

 ### [YouTube Demonstration](https://youtu.be/7eJexJVCqJo)

<h2>Description</h2>
DirSentinel is a versitile Real-time Linux directory monitoring and logging tool made exclusively with bash.
<br />

## Features

- **User Authentication**:
  - Allows registration and secure login with salted and hashed passwords.
  - Ensures sensitive user data is stored securely with restricted access.

- **Directory Monitoring**:
  - Tracks `CREATE` and `DELETE` events for files and directories using `inotifywait` and `auditd`.
  - Logs events, including the user responsible, to a configurable log file.

- **Settings Management**:
  - Configure default log formats (`txt`, `csv`, `html`) and directories.
  - User-friendly `zenity` GUI menus for all settings.

- **Security-Oriented**:
  - Enforces secure file permissions for all sensitive files.
  - Uses a random salt and SHA256 for password hashing.

- **Cross-Platform Dependency Installation**:
  - Automatically checks for and installs missing dependencies using popular package managers (`apt`, `yum`, `dnf`, `pacman`).


<h2>Compatibilities and Dependencies</h2>

- <b>DirSentinel is created entirely in bash. Therefore it is compatible with nearly all modern linux distributions! </b> 
- <b>DirSentinel utilizes the following dependencies:
  - auditd: For monitoring the file system activities
  - inotify-tools: For real-time directory monitoring
  - zenity: For graphical user interface interaction
- Note: If you dot not have these resources installed, dont worry! DirSentinel will check for existing installations for these tools upon execution, and download them for you if it does not detect them as already being installed.</b>

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/DirSentinel.git
   cd DirSentinel

   ## Contributing

Contributions are welcome! If you encounter any issues or have feature requests, feel free to submit an [issue](https://github.com/your-username/DirSentinel/issues) or open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
