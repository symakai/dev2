#!/bin/bash
#########################################################
# Note:
# 1.scripts of devementment and maintenance
# 2.Compatible with CentOS7.x
# author:zhanghao
# groupId:dev2
# version 1.0  20190731
#########################################################
#Source function library.
. /etc/init.d/functions
. ~/.bash_profile
#date
DATE=`date +"%Y-%m-%d %H:%M:%S"`
#ip
IPADDR=`ifconfig | grep "inet" | grep -vE  'inet6|127.0.0.1' | awk '{print $2}' | sed -n '1p'`
#hostname
HOSTNAME=`hostname -s`
#user
USER=`whoami`
#disk_check
DISK_SDA=`df -h | grep -w "/" | grep -v 'host' | awk '{print $5}'`
#cpu_average_check,1min 5min 15min
CPU_AVG=`cat /proc/loadavg | awk '{print $1, $2, $3}'`
#cpu processor 
CPU_PROCESSORS=`cat /proc/cpuinfo | grep -w 'processor' | wc -l`
#cpu cores
#in case of `` awk should like this:awk -F ':\\\\s*' '{print $2}'
CPU_CORES=$(cat /proc/cpuinfo | grep -w 'cpu cores' | awk -F ':\\s*' '{print $2}' | awk '{sum+=$1} END {print sum}')
#cpu_model
CPU_MODEL=$(cat /proc/cpuinfo | grep -w 'model name' | sed -n '1p' | awk -F ':\\s*' '{print $2}')
#memory capcity
MEMORY=$(free -h | sed -n '2p' | awk -F '\\s*' '{print $2}')
#centos version
CENTOS_VERSION=`cat /etc/redhat-release`
#kernel_verison
KERNEL_VERSION=`uname -sr`
#java_version
JAVA_VERSION=`java -version 2>&1 | awk 'NR==1{gsub(/"/,""); print $3}'`
#gcc_version
GCC_VERSION=`gcc --version | grep -w "gcc" | awk '{print $3}'`

#set LANG
export LANG=zh_CN.UTF-8

#Require root to run this script.
#uid=`id | awk -F '(' '{print $1}' | awk -F '=' '{print $2}'`
uid=`id | cut -d\( -f1 | cut -d= -f2`
if [[ $uid != 0 ]]; then
  action "Please run this script as root." /bin/false
  exit 1
fi

# set backspace as erase for root and all login users(/home/*)
configBackspace() {
  echo "================config backspace as erase================"
  echo "config for user:root"
  erase=`grep -wx "stty erase ^H" /root/.bash_profile | wc -l`
  if [[ $erase < 1 ]]; then
    cp /root/.bash_profile  /root/.bash_profile.$(date +%F)
    echo "stty erase ^H" >> /root/.bash_profile
    source /root/.bash_profile
  fi
  for user in `ls /home`
  do
    id $user > /dev/null
    if [[ $? == 0 ]]; then
      cat /etc/passwd | grep -w "$user" | grep "nologin" > /dev/null
      if [[ $? == 0 ]]; then
        continue
      fi
      echo "config for user:${user}"
      erase=`grep -wx "stty erase ^H" /home/$user/.bash_profile | wc -l`
      if [[ $erase < 1 ]]; then
        cp /home/$user/.bash_profile /home/$user/.bash_profile.$(date +%F)
        echo "stty erase ^H" >> /home/$user/.bash_profile
        # source /home/$user/.bash_profile
      fi
    fi
  done

  action "config backspace to erase successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#config Yum CentOS7-aliyun.repo
configYum() {
  echo "==============config yum with aliyun repo================"
  for i in /etc/yum.repos.d/*.repo
  do
    mv $i ${i%.repo}.$(date +%F)
  done
  wget -O /etc/yum.repos.d/CentOS7-aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo > /dev/null 2>&1
  yum clean all;yum makecache;yum repolist
  sleep 5
  action "config aliyun yum repository successfully"  /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#Charset zh_CN.UTF-8
configCharset() {
  echo "=============change charset to zh_CN.UTF-8==============="
  cp /etc/locale.conf  /etc/locale.conf.$(date +%F)
  cat >> /etc/locale.conf<<EOF
LANG="zh_CN.UTF-8"
#LANG="en_US.UTF-8"
EOF
  source /etc/locale.conf
  grep LANG /etc/locale.conf
  action "change charset to zh_CN.UTF-8 successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#Close Selinux and Iptables
configFirewall() {
  echo "==========forbidden selinux and close iptables==========="
  cp /etc/selinux/config /etc/selinux/config.$(date +%F)
  systemctl stop firewalld
  systemctl disable firewalld
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0
  systemctl status firewalld
  iptables -F
  echo 'run cmd:grep SELINUX=disabled /etc/selinux/config ' 
  grep SELINUX=disabled /etc/selinux/config 
  echo 'run cmd:getenforce '
  getenforce
  echo 'run cmd:iptables -L'
  iptables -L
  action "forbidden selinux and close iptables successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#Change sshd default port to 22
configDefaultSSHPort() {
  echo "======confirm ssh port is 22,if not,change to 22========="
  port=$(grep -wE '^Port' /etc/ssh/sshd_config | awk -F '\\s+' '{print $2}')
  if [[ $port != 22 && $port != "" ]]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$(date +%F)
    sed -i "s/$port/Port 22/g" /etc/ssh/sshd_config
  fi 
  systemctl restart sshd.service && action "config ssh port successfully" /bin/true || action "config ssh port failed" /bin/false
  echo "========================================================="
  echo ""
  sleep 2
}

#time sync
configSyncOutTime() {
  echo "================config time sync========================="
  cp /var/spool/cron/root /var/spool/cron/root.$(date +%F) 2>/dev/null
  NTPDATE=`grep ntpdate /var/spool/cron/root 2>/dev/null | wc -l`
  if [[ $NTPDATE == 0 ]]; then
    echo "#times sync by script at $(date +%F)" >> /var/spool/cron/root
    echo "*/5 * * * * /usr/sbin/ntpdate time.windows.com &>/dev/null" >> /var/spool/cron/root
  fi
  echo 'run cmd:crontab -l'  
  crontab -l
  action "config time sync successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}
# configSyncInnerTime() {
# }
readName() {
  read -p "input authorized user name that you want to:" name
  if [[ $name == "" ]]; then
    read -p "input user name is null, quit?[y/n]:" option
    if [[ $option == "y" || $option == "Y" ]]; then
      step="quit"
      return 1;
    else
      authorizationName
    fi
  fi
  step=$1
}
readIp() {
  read -p "input ip address list, for example ip1,ip2,ip3:" ips
  if [[ $ips == "" ]]; then
    read -p "input ip address lists is null, quit?[y/n]:" option
    if [[ $option == "y" || $option == "Y" ]]; then
      step="quit"
      return 1
    else
      authorizationIp
    fi
  fi
  iplist=(${ips//,/ })
  #whether ip format is correct or not
  # for ip in ${iplist[@]}
  local counts=${#iplist[@]}
  for ((i=0; i<counts; i++))
  do
    ip=${iplist[i]}
    echo $ip | grep -wP "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" > /dev/null
    if [[ $? != 0 ]]; then
      echo "$ip format is wrong"
      step="ip"
      return 1
    fi
    for ((j=0; j<counts; j++))
    do
      if [[ $i != $j ]]; then
        if [[ ${iplist[i]} == ${iplist[j]} ]]; then
          echo "there are two same ip address:${iplist[i]}"
          step="ip"
          return 1
        fi
      fi
    done
  done
  step=$1
}
configAuthorization() {
  echo "==================Authorization=========================="
  while true
  do
    case $step in
      "ip")
        readIp "auth"
        ;;
      "auth")
        break
        ;;
      "quit")
        break
        ;;
      "name")
        readName "ip"
        ;;
      *)
        readName "ip"
        ;;
    esac
  done
  if [[ $step == "quit" ]]; then
    return 1
  fi
  if [[ $step == "auth" ]]; then
    local counts=${#iplist[@]}
    for ((i=0; i<counts; i++))
    do
      for ((j=0; j<counts; j++))
      do
        if [[ $i != $j ]]; then
          echo -e "\n*****Authorise ip:${iplist[i]}=>ip:${iplist[j]}*****"
          echo -e "*****login ip:${iplist[i]} with $name******\n"
          ssh -tt -o StrictHostKeyChecking=no $name@${iplist[i]} "\
          echo -e \"\n*****generate rsa key*****\n\" && \
          ssh-keygen -t rsa && \
          echo -e \"\n*****copy id_rsa.pub to ip:${iplist[j]}*****\n\" && \
          ssh-copy-id $name@${iplist[j]} && exit"
          echo ""
          sleep 2 
        fi
      done
    done
  fi
  step="name"
  echo "========================================================="
}

# configAuthorization() {
#   echo "==================Authorization=========================="
#   while true
#   do
#     read -p "input authorized user name that you want to:" name
#     if [[ $name == "" ]]; then
#       read -p "input user name is null, quit?[y/n]:" option
#       if [[ $option == "y" || $option == "Y" ]]; then
#         return 1;
#       else
#         continue
#       fi
#     fi
#     read -p "input ip address list, for example ip1,ip2,ip3:" ips
#     if [[ $ips == "" ]]; then
#       read -p "input ip address lists is null, quit?[y/n]:" option
#       if [[ $option == "y" || $option == "Y" ]]; then
#         return 1
#       else
#         continue
#       fi
#     fi
#     iplist=(${ips//,/ })
#     #whether ip is correct or not
#     for ip in ${iplist[@]}
#     do
#       echo $ip | grep -wP "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" > /dev/null
#       if [[ $? != 0 ]]; then
#         echo "$ip format is wrong"
#       fi
#     done
#     break
#   done
#   echo "========================================================="
# }

#install tools
installTools() {
  echo "========install tree|nmap|sysstat|iotop|dos2unix========="
  ping -c 2 mirrors.aliyun.com
  sleep 2
  yum install tree nmap sysstat iotop dos2unix -y
  sleep 2
  echo ""
  echo "==============install openssl|openssh|bash==============="
  yum install openssl openssh bash -y
  sleep 2
  action "install tools successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}
#add user and give sudoers
addUser() {
  echo "========================add user========================="
  #add user
  while true
  do  
    read -p "user name:" name 
    NAME=`awk -F':' '{print $1}' /etc/passwd | grep -wx $name 2>/dev/null | wc -l`
    if [[ $NAME == "" ]]; then
      echo "user name is null, please input angain"
      continue
    elif [[ $NAME == 1 ]]; then
      echo "user name is used, please choose another"
      continue
    fi
    useradd $name
    break
  done
  #create password
  while true
  do
    read -p "change password for $name:" pass1
    if [[ $pass1 == "" ]]; then
      echo "password is null, please input again"
      continue
    fi
    read -p "input password angin:" pass2
    if [[ $pass1 != $pass2 ]]; then
      echo "two inputs are inconsistent, please input again"
      continue
    fi
    echo "$pass2" | passwd --stdin $name
    break
  done
  sleep 1

  while true
  do
    read -p "add $name to visudo?[y/n]:" option
    if [[ $option == "" ]]; then
      echo "please input y or n"
      continue
    fi
    if [[ $option == "y" ]]; then
      #add visudo
      echo "#####add visudo#####"
      cp /etc/sudoers /etc/sudoers.$(date +%F)
      SUDO=`grep -w "$name" /etc/sudoers | wc -l`
      if [[ $SUDO == 0 ]]; then
          echo "$name  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
          echo 'run cmd:tail -1 /etc/sudoers'
          tail -1 /etc/sudoers
          # grep -w "$name" /etc/sudoers
          sleep 1
      fi
      action "add user $name successfully"  /bin/true
      break
    fi
  done
  echo "========================================================="
  echo ""
  sleep 2
}

#Adjust the file descriptor(limits.conf)
configLimits() {
  echo "===============config file descriptor===================="
  LIMIT=`grep nofile /etc/security/limits.conf | grep -v "^#" | wc -l`
  if [[ $LIMIT == 0 ]]; then
    echo ""
    echo "***limit settting****"
    echo "* soft nofile 65535 *"
    echo "* hard nofile 65535 *"
    echo "* soft nproc  65535 *"
    echo "* hard nproc  65535 *"
    echo "*********************"
    echo ""
    cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
    cat >> /etc/security/limits.conf<<EOF
* soft nofile 65535 
* hard nofile 65535
* soft nproc  65535
* hard nproc  65535
EOF
  fi
  echo 'run cmd:tail -4 /etc/security/limits.conf'
  tail -4 /etc/security/limits.conf
  ulimit -HSn 65535
  echo 'run cmd:ulimit -n'
  ulimit -n
  action "config limit to 65535 successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}


#Optimizing the system kernel
configSysctl() {
  echo "====================config sysctl========================"
  SYSCTL=`grep "net.ipv4.tcp" /etc/sysctl.conf | wc -l`
  if [[ $SYSCTL < 10 ]]; then
    cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%F)
    echo "***************************************"
    echo "net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_rmem=4096 87380 4194304
net.ipv4.tcp_wmem=4096 16384 4194304
net.ipv4.tcp_keepalive_time = 600 
net.ipv4.tcp_keepalive_probes = 5 
net.ipv4.tcp_keepalive_intvl = 15 
net.ipv4.route.gc_timeout = 100
net.ipv4.ip_local_port_range = 1024 65000 
net.ipv4.icmp_echo_ignore_broadcasts=1
net.core.somaxconn = 16384 
net.core.netdev_max_backlog = 16384"
    echo "***************************************"
    cat >> /etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_rmem=4096 87380 4194304
net.ipv4.tcp_wmem=4096 16384 4194304
net.ipv4.tcp_keepalive_time = 600 
net.ipv4.tcp_keepalive_probes = 5 
net.ipv4.tcp_keepalive_intvl = 15 
net.ipv4.route.gc_timeout = 100
net.ipv4.ip_local_port_range = 1024 65000 
net.ipv4.icmp_echo_ignore_broadcasts=1
net.core.somaxconn = 16384 
net.core.netdev_max_backlog = 16384
EOF
  fi
  sysctl -p
  action "kernel setting successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#setting history
configHistory() {
  echo "=============history command size=2000==================="
  # echo "TMOUT=600" >> /etc/profile
  echo "HISTSIZE=2000" >> /etc/profile
  echo "HISTTIMEFORMAT='%F %T `whoami`=> '" >> /etc/profile
  source /etc/profile
  action "config history successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#lock system file
# lockFile() {
#   echo "======================lock system file==================="
#   chattr +i /etc/passwd
#   chattr +i /etc/inittab
#   chattr +i /etc/group
#   chattr +i /etc/shadow
#   chattr +i /etc/gshadow
#   /bin/mv /usr/bin/chattr /usr/bin/lock
#   action "lock system file successfully" /bin/true
#   echo "==========================================================="
#   echo ""
#   sleep 2
# }

clear
echo "========================================"
echo "          Dev2 Linux Config             "
echo "========================================"
echo ""
cat << EOF
|-----------System Infomation-----------
| DATE           :$DATE
| HOSTNAME       :$HOSTNAME
| USER           :$USER
| IP             :$IPADDR
| DISK_USED      :$DISK_SDA
| CPU_PROCESSORS :$CPU_PROCESSORS
| CPU_CORES      :$CPU_CORES
| CPU_MODEL      :$CPU_MODEL
| MEMORY         :$MEMORY
| CNETOS         :$CENTOS_VERSION
| KERNEL         :$KERNEL_VERSION
| JAVA           :$JAVA_VERSION
| GCC            :$GCC_VERSION
|---------------------------------------
EOF

while true;
do
  echo ""
  cat <<EOF
(1)  新建用户并选择是否加入sudoers
(2)  外网配置aliyun YUM源
(3)  配置中文字符集(zh_CN.UTF-8)
(4)  禁用SELINUX及关闭防火墙
(5)  修改ssh默认端口为22
(6)  设置默认历史记录数(2000)
(7)  安装系统工具
(8)  配置文件描述符(65535)
(9)  系统内核调优
(10) 设置外网时间同步
(11) 设置内网集群时间同步(需授信)
(12) 集群授信 
(13) 设置backspace为删除键
(0)  退出 
EOF
  read -p "Please enter your Choice[0-13]: " input1
  case "$input1" in
    0)
      clear
      break 
      ;;
    1)
      addUser
      ;;
    2)
      configYum
      ;;
    3)
      configCharset
      ;;
    4)
      configFirewall
      ;;
    5)
      configDefaultSSHPort
      ;;
    6)
      configHistory
      ;;
    7)
      installTools 
      ;;
    8)
      configLimits
      ;;
    9)
      configSysctl
      ;;
    10)
      configOutSyncTime
      ;;
    11)
      configInnerSyncTime
      ;;
    12)
      configAuthorization
      ;;
    13)
      configBackspace
      ;;
    *)
      echo "----------------------------------"
      echo "|   Please Enter Right Choice!   |"
      echo "----------------------------------"
      for i in `seq -w 3 -1 1`
      do 
        echo -ne "\b\b$i"
        sleep 1
      done
      clear
  esac
done
