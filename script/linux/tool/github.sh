#!/bin/bash
#****************************************************
# Utility of generate ip lists by domains of github 
# @author:zhanghao
# @groupId:dev2
# @version 1.0
# @date 20200830
#****************************************************
hosts=(
www.github.com \
github.com \
assets-cdn.github.com \
documentcloud.github.com \
gist.github.com \
help.github.com \
nodeload.github.com \
codeload.github.com \
raw.github.com \
raw.githubusercontent.com \
status.github.com \
training.github.com \
github.githubassets.com \
cloud.githubusercontent.com \
avatars0.githubusercontent.com \
avatars1.githubusercontent.com \
avatars2.githubusercontent.com \
avatars3.githubusercontent.com
)
IP_URL="ipaddress.com"
# hosts=('www.baidu.com' 'github.com')
ips=()
errs=()
idx=0
# curl connect timeout
CONNECT_TIMEOUT=5
# curl get data timeout
TRANSFER_TIMEOUT=15

cat /etc/redhat-release > /dev/null 2>&1 && OS=LINUX || OS=WIN

function search_ip() {
    local domain=$1
    local host=$2
    local qry_host=${domain}.${IP_URL}/${host}
    local ret=0
    echo -e "\033[36m${qry_host}\033[0m"
    curl -L --connect-timeout ${CONNECT_TIMEOUT} -m ${TRANSFER_TIMEOUT} -Ss -o ${host}.html ${qry_host}
    ret=$?
    grep -E -q '404 Page Not Found' ${host}.html 
    if [[ $? == 0 ]]; then
        qry_host2=${domain}.${IP_URL}
        echo -e "\033[36m${qry_host2}\033[0m"
        curl -L --connect-timeout ${CONNECT_TIMEOUT} -m ${TRANSFER_TIMEOUT} -Ss -o ${host}.html ${qry_host2}
        ((ret=ret+$?))
    fi
    grep -E -q '404 Page Not Found' ${host}.html
    if [[ $? == 0 ]]; then
        echo -e "\033[36msearch ${host} failed with ${qry_host} and ${qry_host2}\033[0m"
        return 1
    fi
    return ${ret}
}

function get_ip() {
    local file=$1.html
    local host=$1
    rm -rf rps
    # ungreedy
    ret=$(grep -P -o "<th>IP Address(es)*?</th>.*?(<li>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}</li>){1,}" ${file})
    echo ${ret} | grep -q "IP Addresses"
    if [[ $? == 0 ]]; then
        local ip_arr=($(echo ${ret} | grep -P -o "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"))
        local i
        for ((i=0; i<${#ip_arr[@]}; i++)) do
            local start=$(date +%s)
            if [[ ${OS} == "WIN" ]]; then
                ping -n 5 ${ip_arr[i]} > /dev/null
            else
                ping -c 5 ${ip_arr[i]} > /dev/null
            fi
            local end=$(date +%s)
            ((diff=${end}-${start}))
            echo "${diff} ${ip_arr[i]}" >> rps
        done
        if [[ -f rps ]]; then
            ip=$(cat rps | sort -g -t " " -k 1 | sed -n '1p' | awk -F ' ' '{print $2}')
        else
            echo -e "\033[36msomething was wrong\033[0m"
        fi
    else
        ip=$(echo ${ret} | grep -P -o "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
    fi
    ips[idx]="${ip} ${host}"
    ((idx++))
    rm -rf rps
    return 0
}

cnt=0
for ((i=0; i<${#hosts[@]}; i++)) do
    host=${hosts[i]}
    echo -e "\033[36mURL:${host}\033[0m"
    echo "${host}" | grep -E -q 'w{3}\..*'
    if [[ $? == 0 ]]; then
        # URL likes www.xxx.com 
        domain=${host#www.}
    else
        # URL likes xxx.com
        domain=${host}
    fi
    search_ip ${domain} ${host} && get_ip ${host} || { errs[cnt]=${host}; ((cnt++)); }
    rm -rf ${host}.html
done

for ((i=0; i<${#ips[@]}; i++)) do
    echo ${ips[i]}
    if [[ ${OS} == "WIN" ]]; then
        host_path="C:\\Windows\\System32\\drivers\\etc\\hosts"
    else
        host_path="/etc/hosts"
    fi
    host=$(echo ${ips[i]} | awk -F ' ' '{print $2}')
    grep -E -o -q "${host}" "${host_path}"
    if [[ $? == 0 ]]; then
        sed -E -i "s/^([0-9]+\.){3}[0-9]+ ${host}/${ips[i]}" ${host_path}
    else
        echo ${ips[i]} >> ${host_path}
    fi
done

if [[ ${OS} == "WIN" ]]; then
    ipconfig -flushdns
fi

if [[ ${#errs[@]} -gt 0 ]]; then
    echo -e "\033[36m******Failed ip lists******\033[0m"
    for ((i=0; i<${#errs[@]}; i++)) do
        echo ${errs[i]}
    done
fi
