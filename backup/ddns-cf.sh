#!/bin/sh
#By  wimotek

#Dependences: curl 可选iproute2,dnsutils

## ----- Setting -----
AccessKeyId="aaa@163.com"
AccessKeySec="f24xxxxcee674c4xxxx5c93xxxc2"
DomainZoneID="d572xxxdbdb6e4b2xxxxe7904"
DomainRecordId="a69a45449xxxxxb79a26867c92"

DomainName="a.b.com"
DomainType="AAAA"


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
       local old_ip=$(ping6 -c 1  ${DomainName}|grep PING|sed -n 's/.*(\([0-9a-f:]\+\)\+).*/\1/p')
       #local old_ip=$(echo $(nslookup -query=AAAA gdgz.eu.org)|grep Address|awk '{print $NF}')
       _func_ret=${old_ip}
}

get_my_ip()
{
	reset_func_ret
	local my_ip=$(curl ${MyIPEchoUrl} --silent --connect-timeout 10)
  #local my_ip=$(sudo ip -6 addr list scope global |grep "inet6" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)
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
