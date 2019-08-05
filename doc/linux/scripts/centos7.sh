#!/bin/bash
#########################################################
# Note:
# 1.utility of devementment and maintenance
# 2.compatible with CentOS7.x
# author:zhanghao
# groupId:dev2
# version 1.0.0  20190731 init
#########################################################
#Source function library.
. /etc/init.d/functions
. ~/.bash_profile
#date
DATE=$(date +"%Y-%m-%d %H:%M:%S")
#ip
IPADDR=$(ifconfig | grep "inet" | grep -vE  'inet6|127.0.0.1' | awk '{print $2}' | sed -n '1p')
#hostname
HOSTNAME=$(hostname -s)
#user
USER=$(whoami)
#disk_check
DISK_SDA=$(df -h | grep -w "/" | grep -v 'host' | awk '{print $5}')
#cpu_average_check,1min 5min 15min
CPU_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
#cpu processor 
CPU_PROCESSORS=$(cat /proc/cpuinfo | grep -w 'processor' | wc -l)
#cpu cores
#in case of `` awk should like this:awk -F ':\\\\s*' '{print $2}'
CPU_CORES=$(cat /proc/cpuinfo | grep -w 'cpu cores' | awk -F ':\\s*' '{print $2}' | awk '{sum+=$1} END {print sum}')
#cpu_model
CPU_MODEL=$(cat /proc/cpuinfo | grep -w 'model name' | sed -n '1p' | awk -F ':\\s*' '{print $2}')
#memory capcity
MEMORY=$(free -h | sed -n '2p' | awk -F '\\s*' '{print $2}')
#centos version
CENTOS_VERSION=$(cat /etc/redhat-release)
#kernel_verison
KERNEL_VERSION=$(uname -sr)
#java_version
JAVA_VERSION=$(java -version 2>&1 | awk 'NR==1{gsub(/"/,""); print $3}')
#gcc_version
GCC_VERSION=$(gcc --version | grep -w "gcc" | awk '{print $3}')

#set LANG
export LANG=zh_CN.UTF-8

#Require root to run this script.
#uid=`id | awk -F '(' '{print $1}' | awk -F '=' '{print $2}'`
uid=`id | cut -d\( -f1 | cut -d= -f2`
if [[ $uid != 0 ]]; then
  action "Please run this script as root." /bin/false
  exit 1
fi


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
    action "add user $name successfully"  /bin/true
    break
  done
  sleep 1

  while true
  do
    read -p "add $name to sudoer?[y/n]:" option
    if [[ $option == "" ]]; then
      echo "please input y or n"
      continue
    fi
    if [[ $option == "y" || $option == "Y" ]]; then
      #add visudo
      echo -e "\n*****add sudoer******\n"
      cp /etc/sudoers /etc/sudoers.$(date +%F)
      SUDO=`grep -w "$name" /etc/sudoers | wc -l`
      if [[ $SUDO == 0 ]]; then
          echo "$name  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
          echo "run cmd:tail -1 /etc/sudoers"
          tail -1 /etc/sudoers
          # grep -w "$name" /etc/sudoers
          sleep 1
      fi
      action "add sudoer successfully"  /bin/true
    fi
    break
  done
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
  # wget -O /etc/yum.repos.d/CentOS7-aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo > /dev/null 2>&1
  curl -o /etc/yum.repos.d/CentOS7-aliyun.repo http://mirrors.aliyun.com/repo/Centos-7.repo > /dev/null 2>&1
  if [[ $? != 0 ]]; then
    action "config aliyun yum repository failed"  /bin/false
  else
    yum clean all;yum makecache;yum repolist
    sleep 2
    action "config aliyun yum repository successfully"  /bin/true
  fi
  echo "========================================================="
  echo ""
  sleep 2
}

#Charset zh_CN.UTF-8
configCharset() {
  echo "==============config LC_CTYPE=zh_CN.UTF-8================"

  #config root
  linenum=$(grep -wn "^LC_CTYPE" ~/.bash_profile | awk -F ':' '{print $1}')
  if [[ $linenum != 0 && $linenum != "" ]]; then
    sed -in "${linenum}c LC_CTYPE=zh_CN.UTF-8" ~/.bash_profile 
  else
    echo "LC_CTYPE=zh_CN.UTF-8" >> ~/.bash_profile 
  fi
  . ~/.bash_profile
  action "config root with LC_CTYPE=zh_CN.UTF-8 successfully" /bin/true 
  #config other users
  read -p "config other users with LC_CTYPE?[y/n]:" option 
  if [[ $option == "y" || $option == "Y" ]]; then
    for user in `ls /home`
    do
      id $user > /dev/null 2>&1
      if [[ $? == 0 ]]; then
        cat /etc/passwd | grep -w "$user" | grep "nologin" > /dev/null
        if [[ $? == 0 ]]; then
          continue
        fi
        echo "config for user:${user}"
        linenum=$(grep -wn "^LC_CTYPE" /home/$user/.bash_profile | awk -F ':' '{print $1}')
        if [[ $linenum != 0 && $linenum != "" ]]; then
          sed -in "${linenum}c LC_CTYPE=zh_CN.UTF-8" /home/$user/.bash_profile 
        else
          echo "LC_CTYPE=zh_CN.UTF-8" >> /home/$user/.bash_profile 
        fi
        . /home/$user/.bash_profile
      fi
    done
  fi
  action "config other users with LC_CTYPE=zh_CN.UTF-8 successfully" /bin/true 
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
    sed -i "s/Port=$port/Port=22/g" /etc/ssh/sshd_config
    systemctl restart sshd.service && action "config ssh port successfully" /bin/true || action "config ssh port failed" /bin/false
  else
    echo "change nothing,ssh port has been set to 22"
  fi 
  echo "========================================================="
  echo ""
  sleep 2
}

#setting history
configHistory() {
  echo "=============history command size=2000==================="
  linenum=$(grep -wn "^HISTSIZE" /etc/profile | awk -F ':' '{print $1}')
  if [[ $linenum != 0 && $linenum != "" ]]; then
    sed -in "${linenum}c HISTSIZE=2000" /etc/profile
  else
    echo "HISTSIZE=2000" >> /etc/profile
  fi
  linenum=$(grep -wn "^HISTTIMEFORMAT" /etc/profile | awk -F ':' '{print $1}')
  if [[ $linenum != 0 && $linenum != "" ]]; then
    sed -in "${linenum}c HISTTIMEFORMAT='%F %T \`whoami\`=> '" /etc/profile
  else
    echo "HISTTIMEFORMAT='%F %T `whoami`=> '" >> /etc/profile
  fi
  source /etc/profile && action "config history successfully" /bin/true || action "config history failed" /bin/false
  echo "========================================================="
  echo ""
  sleep 2
}

#install tools
installTools() {
  echo "======install sysstat|dos2unix|openssl|openssh|bash======"
  ping -c 2 mirrors.aliyun.com
  sleep 1
  yum install sysstat dos2unix openssl openssh bash -y
  sleep 1
  action "install tools successfully" /bin/true
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
    echo "*********************"
    echo ""
    cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
    cat >> /etc/security/limits.conf<<EOF
* soft nofile 65535 
* hard nofile 65535
EOF
  fi

  LIMIT=`grep nproc /etc/security/limits.conf | grep -v "^#" | wc -l`
  if [[ $LIMIT == 0 ]]; then
    echo ""
    echo "***limit settting****"
    echo "* soft nproc  65535 *"
    echo "* hard nproc  65535 *"
    echo "*********************"
    echo ""
    cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
    cat >> /etc/security/limits.conf<<EOF
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
  if [[ $SYSCTL < 1 ]]; then
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
    read -p "is this ok?[y/n]:" option
    if [[ $option == "y" || $option == "Y" ]]; then
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
      sysctl -p && action "kernel setting successfully" /bin/true || action "kernel setting failed" /bin/false
    fi
  fi
  echo "========================================================="
  echo ""
  sleep 2
}

#time sync
configOuterSyncTime() {
  echo "================config internet time sync================"
  NTPDATE=`grep ntpdate /var/spool/cron/root 2>/dev/null | wc -l`
  if [[ $NTPDATE == 0 ]]; then
    yum list installed | grep -w ntpdate > /dev/null 2>&1
    if [[ $? != 0 ]]; then
      yum install ntpdate -y
    fi
    cp /var/spool/cron/root /var/spool/cron/root.$(date +%F) 2>/dev/null
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
configInnerSyncTime() {
  echo "================config intranet time sync================"
  sync="ntpd"
  while true
  do
    case $sync in
      "ntpd")
        read -p "input ntp server ip:" ntpserver
        if [[ $ntpserver == "" ]]; then
          continue
        fi
        sync="ntpc"
        ;;
      "ntpc")
        sync=
        readIp "" "ntp client ip list"
        ;;
      *)
        break
        ;;
    esac
  done
  echo -e "\n*****config ntp server($ntpserver)*****\n"
  ssh -o StrictHostKeyChecking=no root@$ntpserver '\
  rpm -q ntp > /dev/null || yum list installed | grep -w ntp > /dev/null;
  if [[ $? != 0 ]]; then
    echo -e "\n******install ntpd*******\n";
    yum install ntp -y;
  fi
  if [[ $? == 0 ]]; then
    ls /etc/ntp.conf.origin > /dev/null 2>&1;
    if [[ $? != 0 ]]; then
      cp /etc/ntp.conf /etc/ntp.conf.origin> /dev/null 2>&1;
    else
      cp /etc/ntp.conf /etc/ntp.conf.$(date +%F) > /dev/null 2>&1;
    fi
    cat > /etc/ntp.conf <<EOF
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
server 127.127.1.0
fudge  127.127.1.0 stratum 10
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF
    systemctl enable ntpd;
    systemctl start  ntpd;
  else
    echo -e "\n******install ntpd failed******\n";
  fi
  '
  local counts=${#iplist[@]}
  for ((i=0; i<counts; i++))
  do
    if [[ ${iplist[i]} == $ntpserver ]]; then
      echo -e "\nclient ip(${iplist[i]}) is same as ntpserver,skip this ip\n"
      continue
    fi
    echo -e "\n*****config ntp client(${iplist[i]})******\n"
    ssh -o StrictHostKeyChecking=no root@${iplist[i]} "
    rpm -q ntpdate > /dev/null || yum list installed | grep -w ntpdate > /dev/null;
    if [[ \$? != 0 ]]; then
      echo -e \"\n******install ntpdate*******\n\";
      yum install ntpate -y;
    fi
    if [[ \$? == 0 ]]; then
      /usr/sbin/ntpdate $ntpserver
      cp /var/spool/cron/root /var/spool/cron/root.\$(date +%F) 2>/dev/null
      line=\$(grep -nw '/usr/sbin/ntpdate' /var/spool/cron/root | awk -F':' '{print \$1}')
      if [[ \$line == \"\" ]]; then
        echo \"*/30 * * * * /usr/sbin/ntpdate $ntpserver\" >> /var/spool/cron/root
      else
        sed -i \"\${line}c */30 * * * * /usr/sbin/ntpdate $ntpserver\" /var/spool/cron/root
      fi
      echo \"run remote cmd: crontab -l\"
      crontab -l
    else
      echo -e \"\n******install ntpdate failed******\n\"
    fi
    "
  done
  [ $? == 0 ] && action "config intranet time sync completely" /bin/true || action "config intranet time sync failed" /bin/false
  echo 
  echo "========================================================="
  echo ""
  sleep 2
}
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
  read -p "input $2, for example ip1,ip2,ip3:" ips
  if [[ $ips == "" ]]; then
    read -p "input ip address lists is null, quit?[y/n]:" option
    if [[ $option == "y" || $option == "Y" ]]; then
      step="quit"
      return 1
    else
      readIp $1 $2
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
        readIp "auth" "ip list"
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
    echo ""
    echo "******************************************************************************"
    echo "* 1.please input user name"
    echo "* 2.please input ip list that you want to authorise"
    echo "* 3.please input [enter|y] according to the prompt"
    echo "* 4.if authorization does not work"
    echo "*   a)please confirm permission of ~/.ssh/authorized_keys is 0600(-rw-------)"
    echo "*   b)please confirm permission of /home/xxx is 0700(drwx------)"
    echo "******************************************************************************"
    echo ""
    local counts=${#iplist[@]}
    #cat ~/.ssh/id_rsa.pub | ssh user@machine "mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys"
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
    id $user > /dev/null 2>&1
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

clear
echo ""
# cat <<EOF
echo -e "\033[36m|--------------------System Infomation----------------------"
echo -e "\033[36m| DATE           :$DATE"
echo -e "\033[36m| HOSTNAME       :$HOSTNAME"
echo -e "\033[36m| USER           :$USER"
echo -e "\033[36m| IP             :$IPADDR"
echo -e "\033[36m| DISK_USED      :$DISK_SDA"
echo -e "\033[36m| CPU_PROCESSORS :$CPU_PROCESSORS"
echo -e "\033[36m| CPU_CORES      :$CPU_CORES"
echo -e "\033[36m| CPU_MODEL      :$CPU_MODEL"
echo -e "\033[36m| TOTAL MEMORY   :$MEMORY"
echo -e "\033[36m| CNETOS         :$CENTOS_VERSION"
echo -e "\033[36m| KERNEL         :$KERNEL_VERSION"
echo -e "\033[36m| JAVA           :$JAVA_VERSION"
echo -e "\033[36m| GCC            :$GCC_VERSION"
echo -e "\033[36m|-----------------------------------------------------------\033[0m"
# EOF

while true
do
  echo ""
  # cat <<EOF
echo -e "\033[36m*==========================================================*"
echo -e "\033[36m*                    Dev2 Linux Utility                    *"
echo -e "\033[36m*==========================================================*"
echo -e "\033[36m(1)  新建用户并选择是否加入sudoers"
echo -e "\033[36m(2)  外网配置YUM源(aliyun)"
echo -e "\033[36m(3)  配置中文字符集(LC_CTYPE=zh_CN.UTF-8)"
echo -e "\033[36m(4)  禁用SELINUX及关闭防火墙"
echo -e "\033[36m(5)  修改ssh默认端口为22"
echo -e "\033[36m(6)  设置默认历史记录数(command history=2000)"
echo -e "\033[36m(7)  安装系统工具(dos2unix|sysstat|openssl|openssh|bash)"
echo -e "\033[36m(8)  配置打开文件与进程数量(nofile&&nproc=65535)"
echo -e "\033[36m(9)  系统内核调优(使用前需确认默认参数)"
echo -e "\033[36m(10) 设置外网时间同步"
echo -e "\033[36m(11) 设置内网集群时间同步"
echo -e "\033[36m(12) 集群环境双向授信 "
echo -e "\033[36m(13) 设置backspace为删除键"
echo -e "\033[36m(0)  退出 \033[0m"
# EOF
  read -p "Please enter your choice[0-13]: " input1
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
      configOuterSyncTime
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
      echo "|   Please enter right choice!   |"
      echo "----------------------------------"
      sleep 1
      # for i in `seq -w 2 -1 1`
      # do 
      #   echo -ne "\b\b$i"
      #   sleep 1
      # done
      clear
  esac
done