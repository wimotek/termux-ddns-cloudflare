#!/data/data/com.termux/files/usr/bin/bash
# 配置变量
CLOUDFLARE_API_TOKEN="dnDYixxxxxxxxxxxxxxxxxxxxxxVG_lyN"  # 替换为你的 Cloudflare API Token
DOMAIN_NAME="a.b.com"                  # 替换为你的域名
RECORD_TYPE="AAAA"                         # 替换为你要查找的记录类型（A、CNAME 等）

# 检查 termux-service 是否安装
if ! pkg list-installed | grep -q "termux-services"; then
    echo "termux-services 未安装，正在安装..."
    pkg install termux-services -y
    if [ $? -ne 0 ]; then
        echo "安装 termux-services 失败，请检查网络连接并重试。"
        exit 1
    fi
    echo "termux-services 安装成功。"
fi

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，正在安装..."
    pkg install jq -y
    if [ $? -ne 0 ]; then
        echo "安装 jq 失败，请检查网络连接并重试。"
        exit 1
    fi
    echo "jq 安装成功。"
fi

# 获取 Zone ID
get_zone_id() {
    local domain="$1"
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
                         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                         -H "Content-Type: application/json")
    local zone_id=$(echo "$response" | jq -r '.result[0].id')
    if [ "$zone_id" == "null" ]; then
        echo "错误：无法找到域名 $domain 的 Zone ID。请检查域名是否正确。"
        exit 1
    fi
    echo "$zone_id"
}

# 获取 DNS 记录 ID
get_record_id() {
    local zone_id="$1"
    local record_type="$2"
    local record_name="$3"
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type&name=$record_name" \
                         -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                         -H "Content-Type: application/json")
    local record_id=$(echo "$response" | jq -r '.result[0].id')
    if [ "$record_id" == "null" ]; then
        echo "错误：无法找到记录类型为 $record_type 的 DNS 记录 $record_name。请检查记录类型和名称是否正确。"
        exit 1
    fi
    echo "$record_id"
}


# 主程序
echo "正在获取域名 $DOMAIN_NAME 的 Zone ID..."
ZONE_ID=$(get_zone_id "$DOMAIN_NAME")
echo "Zone ID: $ZONE_ID"

echo "正在获取 DNS 记录 $DOMAIN_NAME 的 Record ID..."
RECORD_ID=$(get_record_id "$ZONE_ID" "$RECORD_TYPE" "$DOMAIN_NAME")
echo "Record ID: $RECORD_ID"


# 创建 ddns-cf 服务脚本
SERVICE_NAME="ddns-cf"
mkdir -p $PREFIX/var/service/$SERVICE_NAME/log
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/$SERVICE_NAME/log/run

cat >$PREFIX/var/service/$SERVICE_NAME/run  <<EOF
#!/data/data/com.termux/files/usr/bin/bash

#配置参数
   \$YOUR_API_TOKEN="$CLOUDFLARE_API_TOKEN"
   \$YOUR_ZONE_ID=“$ZONE_ID”
   \$YOUR_RECORD_ID="$RECORD_ID"
   \$YOUR_DOMAIN="$DOMAIN_NAME"
   \$YOUR_RECORD_TYPE="$RECORD_TYPE"

# 获取 DNS 记录的 IPv6 地址
get_record_ipv6() {
    local record_name="\$1"
    # 使用 nslookup 获取 DNS 记录的 IPv6 地址
    # local record_ipv6=\$(nslookup -query=AAAA "\$record_name" | grep "Address" | awk '{print \$2}' | tail -n 1)
    # 使用 ping6 测试 DNS 记录的 IPv6 地址
    # local record_ipv6=\$(ping6 -c 1 "\$record_name" | grep "bytes from" | awk '{print \$4}' | cut -d':' -f1-4)
    local record_ipv6=\$(ping6 -c 1 "\$record_name" 2>/dev/null |sed -n '1s/.*(\([0-9a-fA-F:]\+\)).*/\1/p')
    if [ -z "\$record_ipv6" ]; then
        echo "错误：无法获取 DNS 记录 \$record_name 的 IPv6 地址。"
        exit 1
    fi
    echo "\$record_ipv6"
}

# 获取当前设备的 IPv6 地址
get_current_ipv6() {
    # 使用 curl 获取本机的公网 IPv6 地址
    local ipv6=\$(curl -6 -s https://api64.ipify.org)
    if [ -z "\$ipv6" ]; then
        echo "错误：无法获取当前设备的 IPv6 地址。"
        exit 1
    fi
    echo "\$ipv6"
}


# ddns-cf 服务脚本
while true; do
    echo "ddns-cf 服务正在运行..."

    echo "正在获取当前设备的 IPv6 地址..."
    CURRENT_IPV6=\$(get_current_ipv6)
    echo "当前 IPv6 地址: \$CURRENT_IPV6"

   echo "正在获取 DNS 记录 \$DOMAIN_NAME 的 IPv6 地址..."
   RECORD_IPV6=\$(get_record_ipv6 "\$YOUR_DOMAIN")
   echo "DNS 记录的 IPv6 地址: \$RECORD_IPV6"

   # 比较当前 IPv6 地址和 DNS 记录的 IPv6 地址
   if [ "\$CURRENT_IPV6" == "\$RECORD_IPV6" ]; then
        echo "IPv6 地址相同，无需更新。"
   else
        echo "IPv6 地址不同，正在更新 DNS 记录..."
        # 在这里添加你的 DDNS 更新逻辑
        curl -X POST "https://api.cloudflare.com/client/v4/zones/\$YOUR_ZONE_ID/dns_records/\$YOUR_RECORD_ID" \\
            -H "Authorization: Bearer \$YOUR_API_TOKEN" \\
            -H "Content-Type: application/json" \\
            --data '{"type":"\$YOUR_RECORD_TYPE","name":"\$YOUR_DOMAIN","content":"\$YOUR_IP","ttl":1,"proxied":false}'
        echo "更新完成，请等待生效..."
   fi

   sleep 300  # 每 5 分钟运行一次
done

EOF

# 赋予脚本执行权限
chmod +x $PREFIX/var/service/$SERVICE_NAME/run

# 启用并启动服务
sv-enable $SERVICE_NAME
sv up $SERVICE_NAME

echo "ddns-cf 服务已创建并启动。"
