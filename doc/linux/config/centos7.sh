#!/bin/bash
#########################################################
# Compatible with CentOS7.x
# author:zhanghao
# groupId:dev2
#########################################################
#Source function library.
. /etc/init.d/functions
#date
DATE=`date +"%Y-%m-%d %H:%M:%S"`
#ip
IPADDR=`ifconfig | grep "inet" | grep -vE  'inet6|127.0.0.1' | awk '{print $2}'`
#hostname
HOSTNAME=`hostname -s`
#user
USER=`whoami`
#disk_check
DISK_SDA=`df -h | grep -w "/" | grep -v 'host' | awk '{print $5}'`
#cpu_average_check,1min 5min 15min
CPU_UPTIME=`cat /proc/loadavg | awk '{print $1, $2, $3}'`
#cpu processor 
CPU_PROCESSOR=`cat /proc/cpuinfo | grep -w 'processor' | wc -l`
#cpu cores
CPU_CORES=`cat /proc/cpuinfo | grep -w 'cpu cores' | awk -F ':\\s*' '{print $2}' | awk '{sum+=$1} END {print sum}'`
#cpu_model
CPU_MODEL=`cat /proc/cpuinfo | grep -w 'model name' | sed -n '1p' | awk -F ':\\s*' '{print $2}'`
#memory capcity
CPU_CAPCITY=`free -h | sed -n '2p' | awk -F '\\s*' '{print $2}'`
#centos version
CENTOS_VERSION=`cat /etc/redhat-release`

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
  echo "==============set root backspace config=================="
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
      echo "==============set ${user} backspace config==============="
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
  echo "==============update yum with aliyun repo================"
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
  echo 'run cmd:grep SELINUX=disabled /etc/selinux/config ' 
  grep SELINUX=disabled /etc/selinux/config 
  echo 'run cmd:getenforce '
  getenforce 
  action "forbidden selinux and close iptables successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#Removal system and kernel version login before the screen display
# initRemoval() {
#   echo "====remove kernel version infomation when login====="
#   #must use root user run scripts
#   if    
#     [ $UID -ne 0 ];then
#     echo This script must use the root user ! ! ! 
#     sleep 2
#     exit 0
#   fi
#   cp /etc/redhat-release /etc/redhat-release.$(date +%F)
#   >/etc/redhat-release
#   >/etc/issue
#   action "remove kernel version infomation successfully" /bin/true
#   echo "==================================================="
#   echo ""
#   sleep 2
# }

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
configSyncTime() {
  echo "================config time sync========================="
  cp /var/spool/cron/root /var/spool/cron/root.$(date +%F) 2>/dev/null
  NTPDATE=`grep ntpdate /var/spool/cron/root 2>/dev/null | wc -l`
  if [[ $NTPDATE == 0 ]]; then
    echo "#times sync by lee at $(date +%F)" >> /var/spool/cron/root
    echo "*/5 * * * * /usr/sbin/ntpdate time.windows.com &>/dev/null" >> /var/spool/cron/root
  fi
  echo 'run cmd:crontab -l'  
  crontab -l
  action "config time sync successfully" /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#install tools
initTools() {
  echo "========install tree|nmap|sysstat|iotop|dos2unix========="
  ping -c 2 mirrors.aliyun.com
  sleep 2
  yum install tree nmap sysstat iotop dos2unix -y
  sleep 2
  rpm -qa tree nmap sysstat dos2unix
  sleep 2
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
    read -p "input user name:" name
    NAME=`awk -F':' '{print $1}' /etc/passwd | grep -wx $name 2>/dev/null | wc -l`
    if [[ $NAME == "" ]]; then
      echo "user name can not null,please input angain"
      continue
    elif [[ $NAME == 1 ]]; then
      echo "user name is used,please choose another"
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
      echo "password is null,please input again"
      continue
    fi
    read -p "please input angin:" pass2
    if [[ $pass1 != $pass2 ]]; then
      echo "two inputs are not same,please input again"
      continue
    fi
    echo "$pass2" | passwd --stdin $name
    break
  done
  sleep 1


  #add visudo
  echo "#####add visudo#####"
  cp /etc/sudoers /etc/sudoers.$(date +%F)
  SUDO=`grep -w "$name" /etc/sudoers | wc -l`
  if [[ $SUDO == "" ]]; then
      echo "$name  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
      echo 'run cmd:tail -1 /etc/sudoers'
      grep -w "$name" /etc/sudoers
      sleep 1
  fi
  action "add user $name, add user to sudo successfully"  /bin/true
  echo "========================================================="
  echo ""
  sleep 2
}

#Adjust the file descriptor(limits.conf)
configLimits() {
echo "===============加大文件描述符===================="
  LIMIT=`grep nofile /etc/security/limits.conf |grep -v "^#"|wc -l`
  if [ $LIMIT -eq 0 ];then
  \cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
cat >>/etc/security/limits.conf<<EOF
*  soft nofile 2048
*  hard nofile 65535
*  soft nproc  16384
*  hard nproc  16384
EOF
  fi
  echo '#tail -1 /etc/security/limits.conf'
  tail -1 /etc/security/limits.conf
  ulimit -HSn 65535
  echo '#ulimit -n'
  ulimit -n
action "配置文件描述符为65535" /bin/true
echo "================================================="
echo ""
sleep 2
}


#Optimizing the system kernel
configSysctl() {
echo "================优化内核参数====================="
SYSCTL=`grep "net.ipv4.tcp" /etc/sysctl.conf |wc -l`
if [ $SYSCTL -lt 10 ];then
   \cp /etc/sysctl.conf /etc/sysctl.conf.$(date +%F)
cat >>/etc/sysctl.conf<<EOF
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
action "内核调优完成" /bin/true
echo "================================================="
echo ""
  sleep 2
}

#setting history and login timeout
initHistory(){
echo "======设置默认历史记录数2000和连接超时时间600======"
echo "TMOUT=600" >>/etc/profile
echo "HISTSIZE=2000" >>/etc/profile
echo "HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S => '" >>/etc/profile
source /etc/profile
action "设置默认历史记录数和连接超时时间" /bin/true
echo "================================================="
echo ""
sleep 2
}

#chattr file system
initChattr(){
echo "======锁定关键文件系统======"
chattr +i /etc/passwd
chattr +i /etc/inittab
chattr +i /etc/group
chattr +i /etc/shadow
chattr +i /etc/gshadow
/bin/mv /usr/bin/chattr /usr/bin/lock
action "锁定关键文件系统" /bin/true
echo "================================================="
echo ""
sleep 2
}

ban_ping(){
#内网可以ping 其他不能ping 这个由于自己也要ping测试不一定要设置
echo '#内网可以ping 其他不能ping 这个由于自己也要ping测试不一定要设置'
echo 'iptables -t filter -I INPUT -p icmp --icmp-type 8 -i eth0 -s  0.0.0.0/24 -j ACCEPT'
sleep 10
}

#menu2
menu2(){
while true;
do
 clear
cat <<EOF
----------------------------------------
|****Please Enter Your Choice:[0-15]****|
----------------------------------------
(1)  新建一个用户并将其加入visudo
(2)  配置为国内YUM源镜像和保存YUM源文件
(3)  配置中文字符集
(4)  禁用SELINUX及关闭防火墙
(5)  精简开机自启动
(6)  去除系统及内核版本登录前的屏幕显示
(7)  修改ssh默认端口及禁用root远程登录
(8)  设置时间同步
(9)  安装系统补装工具(选择最小化安装minimal)
(10) 加大文件描述符
(11) 禁用GSSAPI来认证，也禁用DNS反向解析，加快SSH登陆速度
(12) 将ctrl alt delete键进行屏蔽，防止误操作的时候服务器重启
(13) 系统内核调优
(14) 设置默认历史记录数和连接超时时间
(15) 锁定关键文件系统
(16) 定时清理邮件任务
(17) 隐藏系统信息
(18) grub_md5加密
(19) ban_ping
(0) 返回上一级菜单

EOF
 read -p "Please enter your Choice[0-15]: " input2
 case "$input2" in
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
   initI18n
   ;;
   4)
   initFirewall
   ;;
   5)
   initService
   ;;
   6)
   initRemoval
   ;;
   7)
   initSsh
   ;;
   8)
   syncSysTime
   ;;
   9)
   initTools
   ;;
   10)
   initLimits
   ;;
   11)
   initSsh
   ;;
   12)
   initRestart
   ;;
   13)
   initSysctl
   ;;
   14)
   initHistory
   ;;
   15)
   initChattr
   ;;
   16)
   del_file
   ;;
   17)
   hide_info
   ;;
   18)
   grub_md5
   ;;
   19)
   ban_ping
   ;;
   *) echo "----------------------------------"
      echo "|          Warning!!!            |"
      echo "|   Please Enter Right Choice!   |"
      echo "----------------------------------"
      for i in `seq -w 3 -1 1`
        do 
          echo -ne "\b\b$i";
          sleep 1;
        done
      clear
 esac
done
}
#initTools
#menu
while true;
do
 clear
 echo "========================================"
 echo '          Linux Optimization            '   
 echo "========================================"
cat << EOF
|-----------System Infomation-----------
| DATE       :$DATE
| HOSTNAME   :$HOSTNAME
| USER       :$USER
| IP         :$IPADDR
| DISK_USED  :$DISK_SDA
| CPU_AVERAGE:$cpu_uptime
----------------------------------------
|****Please Enter Your Choice:[1-3]****|
----------------------------------------
(1) 一键优化
(2) 自定义优化
(3) 退出
EOF
 #choice
 read -p "Please enter your choice[0-3]: " input1
 case "$input1" in
 1) 
   addUser
   configYum
   initI18n
   initFirewall
   initService
   initRemoval
   initSsh
   syncSysTime
   initTools
   initLimits
   initSsh
   initRestart
   initSysctl
   initHistory
   initChattr
   ;;
 2)
   menu2
   ;;
 3) 
   clear 
   break
   ;;
 *)   
   echo "----------------------------------"
   echo "|          Warning!!!            |"
   echo "|   Please Enter Right Choice!   |"
   echo "----------------------------------"
   for i in `seq -w 3 -1 1`
       do
         echo -ne "\b\b$i";
         sleep 1;
       done
   clear
 esac  
done