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
wget -O /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/antonfastcomet/scripts/main/CentOS-Base.repo > /dev/null
echo -e "\e[42mBase repo URLs have been modified\e[0m"
fi
fi
fi

#Import repo and install Cachewall
echo -e "\e[42mInstalling Cachewall\e[0m"
rpm -ivh https://repo.cachewall.com/cachewall-release.rpm
yum install cachewall -y
yum install cachewall --enablerepo=cachewall-edge -y

#Input license key and validate
echo -e "\e[42mEnter license key:\e[0m"
read license_key

/usr/local/xvarnish/bin/activate --key $license_key

#Enable Cachewall
xvctl enable cachewall
xvctl enable https

#Disable xvbeat
mv /usr/bin/xvbeat /usr/bin/xvbeat-old

#Restart Cachewall
echo -e "\e[42mRestarting Cachewall\e[0m"

cwctl varnish restart

echo -e "\e[42mCachewall has been installed\e[0m"
