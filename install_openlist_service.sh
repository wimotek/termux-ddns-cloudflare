#!/data/data/com.termux/files/usr/bin/bash
#By  wimotek.com 转载请注明出处.

# 检查openlist是否已安装
if ! command -v openlist &> /dev/null
then
    echo "openlist未安装，正在安装..."
    pkg update && pkg upgrade -y
    pkg install git openlist -y
    echo "openlist安装完成"
else
    echo "openlist已安装."
fi

# 创建openlist服务
SERVICE_NAME="openlist"
echo "正在创建$SERVICE_NAME服务..."
mkdir -p $PREFIX/var/service/$SERVICE_NAME/log
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/$SERVICE_NAME/log/run

cat >$PREFIX/var/service/$SERVICE_NAME/run  <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec openlist server
EOF

chmod +x $PREFIX/var/service/$SERVICE_NAME/run

#重新加载Termux的环境
source $PREFIX/etc/profile
# 启动openlist服务
echo "正在启动$SERVICE_NAME服务..."
sv-enable $SERVICE_NAME
sv up $SERVICE_NAME

echo "$SERVICE_NAME服务已启动"
