#!/bin/sh
#By  wimotek

#Dependences: curl 可选iproute2,dnsutils

## ----- Setting -----
AccessKeyId="aaa@163.com"
AccessKeySec="f24xxxxcee674c4xxxx5c93xxxc2"
DomainZoneID="d572xxxdbdb6e4b2xxxxe7904"
DomainRecordId="a69a45449xxxxxb79a26867c92"

DomainName="a.b.com"
DomainType="A"


# A url provided by a third-party to echo the public IP of host
MyIPEchoUrl="https://api6.ipify.org"
# MyIPEchoUrl="http://members.3322.org/dyndns/getip"


## ----- Log level -----
_DEBUG_=true
_LOG_=true
_ERR_=true


## ===== private =====

## ----- global var -----
_func_ret=""


## ----- Base Util -----
_debug()	{ ${_DEBUG_} && echo "> $*"; }
_log() 		{ ${_LOG_}   && echo "* $*"; }
_err() 		{ ${_ERR_}   && echo "! $*"; }

reset_func_ret()
{
	_func_ret=""
}

# ----- Other utils -----
get_my_old_ip()
{
       reset_func_ret
       #local old_ip=$(ping -c 1  ${DomainName}|grep PING|sed -E 's/.*\(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\).*/\1/')
       local old_ip=$(ping -c 1  ${DomainName}|awk -F'[()]' '/PING/{print $2}')
       _func_ret=${old_ip}
}

get_my_ip()
{
	reset_func_ret
  # 检查是否存在 wan0 接口
  #if ifconfig | grep -qw "wan0"; then
  #  echo "wan0 接口存在。"
  #else
  #  echo "wan0 接口不存在。"
  #fi
  #权限问题
  #local my_ip=$(ifconfig wan0 | grep 'inet ' | sed 's/.*inet \([0-9\.]*\).*/\1/')
  #local my_ip=$(ip -f inet addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

  local my_ip=$(ifconfig | grep 'inet ' | grep '192.168' | awk '{print $2}')
	_func_ret=${my_ip}
}


send_request()
{
	reset_func_ret

	get_my_old_ip
	local old_ip=${_func_ret}
    echo My old IP:  ${old_ip}

    reset_func_ret
    get_my_ip
	local my_ip=${_func_ret}
    echo My IP:  ${my_ip}

	if [ "${old_ip}" = "${my_ip}" ]; then
      echo "Your IP no change."
    else
        local respond=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${DomainZoneID}/dns_records/${DomainRecordId}" \
		-H "X-Auth-Email:${AccessKeyId}" -H "X-Auth-Key:${AccessKeySec}" -H "Content-Type: application/json" \
		--data '{"type":"'${DomainType}'","name":"'${DomainName}'","content":"'${my_ip}'","proxied":false}')

	    echo ${respond}
	fi

	_func_ret=${respond}
}


main()
{
      while true
	do
	   echo $(date)
       send_request
	   sleep 300
	done
}

main
