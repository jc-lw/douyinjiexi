#!/bin/bash

cd ~/domains
mkdir -p nezhav1
cd nezhav1

if [ -f nezhav1 ]; then
    echo "nezhav1 已存在，跳过下载。"
else
    wget https://github.com/nezhahq/agent/releases/download/v1.7.3/nezha-agent_freebsd_amd64.zip >/dev/null 2>&1
    unzip nezha-agent_freebsd_amd64.zip >/dev/null 2>&1
    mv nezha-agent nezhav1
    chmod 755 nezhav1
    echo "下载成功"
fi

config_file="config.yml"

# 检查 config.yml 文件是否已存在
if [ -f "$config_file" ]; then
    echo "$config_file 已存在。"
else
    # 提示用户输入 client_secret 和 server
    read -p "请直接输入后台复制的命令: " USER_INPUT

    # 提取参数
    if [[ $USER_INPUT =~ NZ_SERVER=([^ ]+) ]]; then
        NZ_SERVER="${BASH_REMATCH[1]}"
    fi
    if [[ $USER_INPUT =~ NZ_TLS=([^ ]+) ]]; then
        NZ_TLS="${BASH_REMATCH[1]}"
    fi
    if [[ $USER_INPUT =~ NZ_CLIENT_SECRET=([^ ]+) ]]; then
        NZ_CLIENT_SECRET="${BASH_REMATCH[1]}"
    fi

    # 检查必需的环境变量是否存在
    if [ -z "$NZ_CLIENT_SECRET" ] || [ -z "$NZ_SERVER" ]; then
        echo "缺少必要的环境变量: NZ_CLIENT_SECRET 或 NZ_SERVER"
        return
    fi

    # 创建配置文件
    cat <<EOL > "$config_file"
client_secret: $NZ_CLIENT_SECRET
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: false
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 1
server: $NZ_SERVER
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: $NZ_TLS
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: $(uuidgen)
EOL
fi

# 创建 restart.sh 文件
cat <<EOL > restart.sh
#!/bin/bash

# 设置脚本路径
SCRIPT_PATH="serv00-play/alist/start.sh"
WORK_DIR="serv00-play/alist"

# 检查指定端口是否在使用
if ! sockstat -4 -l | grep -q ":$PORT"
then
    # 如果端口没有被占用，则重新启动脚本
    cd "\$WORK_DIR"
    nohup ./start.sh > /dev/null 2>&1 &
    echo "Restarted start.sh at \$(date)" >> "\$WORK_DIR/restart_log.txt"
fi
EOL

# 从 GitHub 获取 bh.sh 内容并创建 start.sh
echo "正在从 GitHub 获取最新的 serv00_public.sh 内容..."
curl -Ls https://raw.githubusercontent.com/jc-lw/douyinjiexi/refs/heads/main/bh.sh > start.sh

# 在 start.sh 开头添加 bash shebang
sed -i '1i#!/bin/bash' start.sh

# 在 start.sh 中添加额外的启动命令
cat <<EOL >> start.sh

# 额外的启动命令
cd ~/domains/nezhav1/
nohup ./nezhav1 -c config.yml >/dev/null 2>&1 &
EOL

# 清理安装包
rm -rf nezha-agent_freebsd_amd64.zip

# 停止已有进程
pkill -f nezhav1
sleep 2

# 赋予权限
chmod +x nezhav1
chmod +x restart.sh
chmod +x start.sh

# 运行生成的脚本
./start.sh
./restart.sh

echo "哪吒监控agent启动完成，已同步 GitHub 的 serv00_public.sh 内容到 start.sh"
