# X-UI 自动安装脚本

一个简单快速的 x-ui 面板一键部署脚本，支持多种 Linux 系统。

## 功能特点

- 🚀 全自动安装，无需手动干预
- 🔒 安装后自动安全配置
- 📱 支持多种系统架构 (amd64/arm64)
- 🛡️ 自动生成强密码和随机端口
- 📊 完整的系统服务管理

## 系统要求

- CentOS 7+
- Ubuntu 16+ 
- Debian 8+
- 内存: ≥ 512MB
- 硬盘: ≥ 1GB

## 一键安装

### 方法一：使用 curl
```bash
bash <(curl -Ls https://raw.githubusercontent.com/xy83953441-hue/x-ui-auto-install/main/install.sh)
