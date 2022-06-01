#!/bin/bash
#Check if the user is logged in as root
if [[ $EUID -ne 0 ]]; then
echo -e "\e[41mYou need to be logged in as the root user.\e[0m"
exit 1
else
#Check CentOS version
if rpm -q centos-release | grep -i "el6" > /dev/null; then
echo -e "\e[42mChecking CentOS 6 base repos\e[0m"
#Check if CentOS 6 base repo is correct
if grep -q "6.10" /etc/yum.repos.d/CentOS-Base.repo > /dev/null && grep -i "/x86_64" /etc/yum.repos.d/CentOS-Base.repo > /dev/null;  then
echo -e "\e[42mBase repos already configured\e[0m"
else
rm -rf /etc/yum.repos.d/CentOS-Base.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/antonchepishev/scripts/main/CentOS-Base.repo > /dev/null
echo -e "\e[42mBase repo URLs have been modified\e[0m"
fi
fi
fi

#Install Epel repo
echo -e "\e[42mInstalling Epel repository\e[0m"
yum install epel-release -y

#Install Redis
echo -e "\e[42mInstalling Redis\e[0m"
yum install redis -y

#Enable and start Redis
if rpm -q centos-release | grep -i "el6" > /dev/null; then
chkconfig redis on
elif rpm -q centos-release | grep -i "el7" > /dev/null; then
systemctl enable redis
fi
service redis start

#Check and confirm if Redis running
if redis-cli ping | grep -i "PONG" >/dev/null; then
echo -e "\e[42mRedis has been installed on port 6379\e[0m"
else
echo -e "\e[42mSomething went wrong\e[0m"
fi
