
#!/bin/bash

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
plain='\033[0m'

# 输出函数
echo_color() {
    echo -e "${1}${2}${plain}"
}

# 显示横幅
show_banner() {
    clear
    echo_color "$blue" "================================================"
    echo_color "$green" "           x-ui 自动安装脚本 v1.0.0"
    echo_color "$yellow" "            GitHub: xy83953441-hue"
    echo_color "$blue" "================================================"
    echo ""
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo_color "$red" "错误：必须使用root用户运行此脚本！"
        echo_color "$yellow" "请使用命令: sudo su 切换到root用户"
        exit 1
    fi
}

# 检查系统
check_system() {
    echo_color "$yellow" "检测系统中..."
    
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    else
        echo_color "$red" "未检测到系统版本，请联系脚本作者！"
        exit 1
    fi
    
    echo_color "$green" "检测到系统: ${release}"
}

# 检查架构
check_arch() {
    arch=$(arch)
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "s390x" || $arch == "amd64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch="arm64"
    else
        arch="amd64"
        echo_color "$yellow" "检测架构失败，使用默认架构: ${arch}"
    fi
    echo_color "$green" "系统架构: ${arch}"
}

# 检查系统版本
check_os_version() {
    os_version=""
    
    if [[ -f /etc/os-release ]]; then
        os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
    fi
    if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
        os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
    fi

    if [[ x"${release}" == x"centos" ]]; then
        if [[ ${os_version} -le 6 ]]; then
            echo_color "$red" "请使用 CentOS 7 或更高版本的系统！"
            exit 1
        fi
    elif [[ x"${release}" == x"ubuntu" ]]; then
        if [[ ${os_version} -lt 16 ]]; then
            echo_color "$red" "请使用 Ubuntu 16 或更高版本的系统！"
            exit 1
        fi
    elif [[ x"${release}" == x"debian" ]]; then
        if [[ ${os_version} -lt 8 ]]; then
            echo_color "$red" "请使用 Debian 8 或更高版本的系统！"
            exit 1
        fi
    fi
    
    echo_color "$green" "系统版本检查通过"
}

# 安装基础依赖
install_base() {
    echo_color "$yellow" "安装系统依赖..."
    
    if [[ x"${release}" == x"centos" ]]; then
        yum update -y
        yum install wget curl tar jq -y
    else
        apt update -y
        apt install wget curl tar jq -y
    fi
    
    if [[ $? -ne 0 ]]; then
        echo_color "$red" "依赖安装失败，请检查网络连接！"
        exit 1
    fi
    
    echo_color "$green" "系统依赖安装完成"
}

# 生成随机配置
generate_random_config() {
    local username=$(head -c 8 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 10)
    local password=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)
    local port=$((RANDOM % 50000 + 10000))
    
    echo "$username $password $port"
}

# 安装x-ui
install_x-ui() {
    echo_color "$yellow" "开始安装 x-ui 面板..."
    
    # 停止现有服务
    systemctl stop x-ui 2>/dev/null
    
    # 下载最新版本
    cd /usr/local/
    echo_color "$yellow" "获取最新版本信息..."
    last_version=$(curl -Lsk "https://api.github.com/repos/FranzKafkaYu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ ! -n "$last_version" ]]; then
        echo_color "$red" "检测 x-ui 版本失败，请检查网络连接！"
        exit 1
    fi
    
    echo_color "$green" "检测到最新版本: ${last_version}"
    
    # 下载并解压
    echo_color "$yellow" "下载 x-ui 面板..."
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/FranzKafkaYu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
    
    if [[ $? -ne 0 ]]; then
        echo_color "$red" "下载 x-ui 失败！"
        exit 1
    fi
    
    # 清理旧版本
    rm -rf /usr/local/x-ui/
    
    # 解压文件
    echo_color "$yellow" "解压文件..."
    tar zxvf x-ui-linux-${arch}.tar.gz
    rm -f x-ui-linux-${arch}.tar.gz
    
    # 安装文件
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    
    # 下载管理脚本
    echo_color "$yellow" "安装管理脚本..."
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/FranzKafkaYu/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    
    echo_color "$green" "x-ui 文件安装完成"
}

# 配置面板
configure_panel() {
    echo_color "$yellow" "配置 x-ui 面板..."
    
    # 生成随机配置
    read -r username password port <<< $(generate_random_config)
    
    # 设置账户密码和端口
    /usr/local/x-ui/x-ui setting -username "$username" -password "$password"
    /usr/local/x-ui/x-ui setting -port "$port"
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    # 等待服务启动
    echo_color "$yellow" "启动 x-ui 服务..."
    sleep 5
    
    # 检查服务状态
    if ! systemctl is-active --quiet x-ui; then
        echo_color "$red" "x-ui 服务启动失败，请检查日志！"
        systemctl status x-ui
        exit 1
    fi
    
    echo_color "$green" "面板配置完成"
}

# 显示安装结果
show_result() {
    local public_ip=$(curl -s ipv4.icanhazip.com 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "你的服务器IP")
    local username password port
    
    # 从数据库读取配置（简化版）
    if [[ -f "/etc/x-ui/x-ui.db" ]]; then
        username=$(/usr/local/x-ui/x-ui 2>&1 | grep "username" | awk '{print $2}' | head -1)
        password=$(/usr/local/x-ui/x-ui 2>&1 | grep "password" | awk '{print $2}' | head -1) 
        port=$(/usr/local/x-ui/x-ui 2>&1 | grep "port" | awk '{print $2}' | head -1)
    else
        # 如果数据库不存在，使用生成的随机值
        read -r username password port <<< $(generate_random_config)
    fi
    
    echo ""
    echo_color "$green" "🎉 x-ui 安装完成！"
    echo_color "$blue" "================================================"
    echo_color "$green" "面板访问地址: http://${public_ip}:${port}"
    echo_color "$green" "用户名: ${username}"
    echo_color "$green" "密码: ${password}"
    echo_color "$blue" "================================================"
    echo ""
    echo_color "$yellow" "⚠️  重要安全提示："
    echo_color "$yellow" "1. 请立即登录面板修改默认密码！"
    echo_color "$yellow" "2. 建议在面板中配置 SSL 证书"
    echo_color "$yellow" "3. 配置防火墙开放端口 ${port}"
    echo_color "$yellow" "4. 建议定期更新系统和面板"
    echo ""
    echo_color "$green" "📖 管理命令:"
    echo_color "$blue" "x-ui              # 显示管理菜单"
    echo_color "$blue" "x-ui start        # 启动面板"
    echo_color "$blue" "x-ui stop         # 停止面板"
    echo_color "$blue" "x-ui status       # 查看状态"
    echo_color "$blue" "x-ui restart      # 重启面板"
    echo_color "$blue" "x-ui update       # 更新面板"
    echo ""
    echo_color "$green" "💡 使用提示："
    echo_color "$blue" "1. 登录面板后添加入站协议"
    echo_color "$blue" "2. 配置客户端连接信息"
    echo_color "$blue" "3. 在客户端导入配置"
    echo ""
}

# 主函数
main() {
    show_banner
    
    # 执行安装步骤
    check_root
    check_system
    check_arch
    check_os_version
    install_base
    install_x-ui
    configure_panel
    show_result
    
    echo_color "$blue" "================================================"
    echo_color "$green" "安装脚本完成！感谢使用！"
    echo_color "$blue" "================================================"
}

# 执行主函数
main "$@"
