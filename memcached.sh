
text/x-generic memcached.sh ( Bourne-Again shell script, ASCII text executable )
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

#Install and enable Memacached
echo -e "\e[42mInstalling Memcached\e[0m"
yum install memcached -y
/etc/init.d/memcached start
chkconfig memcached on

#Install PHP Memcache
echo -e "\e[42mInstalling PHP Memcache\e[0m"
yum install ea-php56-php-memcache -y 
yum install ea-php70-php-memcache -y 
yum install ea-php71-php-memcache -y 
yum install ea-php72-php-memcache -y 
yum install ea-php73-php-memcache -y 
yum install ea-php74-php-memcache -y 
yum install ea-php80-php-memcache -y 
yum install ea-php81-php-memcache -y
yes | /opt/cpanel/ea-php56/root/usr/bin/pecl install memcache-3.0.8
yes | /opt/cpanel/ea-php70/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php71/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php72/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php73/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php74/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php80/root/usr/bin/pecl install memcache-8.0
yes | /opt/cpanel/ea-php81/root/usr/bin/pecl install memcache-8.0


#Bind Memcached to local only and start
cat <<EOF | sudo tee /etc/sysconfig/memcached
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS="-l 127.0.0.1"
EOF

service memcached start

#Restart Apache
echo -e "\e[42mRestarting Apache\e[0m"
service httpd restart

#Check if user daemon should be enabled
echo -e "\e[42mWould you like to start the process for a specific user? (Yes/No)\e[0m"
read start_process
if [[ $start_process == "No" || $start_process == "no" ]]; then
echo -e "\e[42mMemcached is running on the server port 11211.\e[0m"
else
echo -e "\e[42mEnter cPanel username:\e[0m"
read cpanel_user

echo -e "\e[42mEnter open port:\e[0m"
read port

memcached -u $cpanel_user -d -m 128 -p $port
#Check if Memcached running and confirm
if netstat -napt | grep $port
then
echo -e "\e[42mMemcached has been enabled for "$cpanel_user" on port $port\e[0m"
else
echo -e "\e[42mSomething went wrong\e[0m"
fi
fi
