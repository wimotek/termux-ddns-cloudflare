# termux-ddns-cloudflare
update your ipv6 address to your domain on cloudflare every 5 minutes


需要设置以下两个参数。
>CLOUDFLARE_API_TOKEN="dnDYixxxxxxxxxxxxxxxxxxxxxxVG_lyN"  # 替换为你的 Cloudflare API Token
>
>DOMAIN_NAME="a.b.com"                  # 替换为你的域名

运行后， 自动添加ddns_cf服务。 启动后自动运行。 

查看脚本日志
>cat $PREFIX/var/log/sv/ddns-cf/current

