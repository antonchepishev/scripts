#!/bin/bash
#Check if the user is logged in as root
if [[ $EUID -ne 0 ]]; then
echo -e "\e[41mYou need to be logged in as the root user.\e[0m"
exit 1
fi
#Check CentOS version
if rpm -q centos-release | grep -i "el6" > /dev/null; then
echo -e "\e[42mChecking CentOS 6 base repos\e[0m"
#Check if CentOS 6 base repo is correct
if grep -q "6.10" /etc/yum.repos.d/CentOS-Base.repo > /dev/null && grep -i "/x86_64" /etc/yum.repos.d/CentOS-Base.repo > /dev/null;  then
echo -e "\e[42mBase repos already configured\e[0m"
else
rm -rf /etc/yum.repos.d/CentOS-Base.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo https://raw.githubusercontent.com/antonchepishev/scripts/main/CentOS-Base.repo > /dev/null;
echo -e "\e[42mBase repo URLs have been modified\e[0m"
fi
fi
  
echo -e "\e[42mWhich service would you like to install? redis,cachewall,memcached,elasticsearch\e[0m"
read -r service
if [ "$service" == "memcached" ]; then
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

if grep -i "CentOS" /etc/redhat-release > /dev/null 2>&1; then
yes | /opt/cpanel/ea-php56/root/usr/bin/pecl install memcache-3.0.8
yes | /opt/cpanel/ea-php70/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php71/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php72/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php73/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php74/root/usr/bin/pecl install memcache-4.0.5.2
yes | /opt/cpanel/ea-php80/root/usr/bin/pecl install memcache-8.0
yes | /opt/cpanel/ea-php81/root/usr/bin/pecl install memcache-8.0
fi

#Bind Memcached to local only and start
cat <<EOF | sudo tee /etc/sysconfig/memcached
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS="-l 127.0.0.1"
EOF
echo -e "\e[42mMemcached set to localhost only\e[0m"

service memcached start

#Restart Apache
echo -e "\e[42mRestarting Apache\e[0m"
service httpd restart

#Check if user daemon should be enabled
echo -e "\e[42mWould you like to start the process for a specific user? (Yes/No)\e[0m"
read -r start_process
if [[ "$start_process" == "No" || $start_process == "no" ]]; then
echo -e "\e[42mMemcached is running on the server port 11211.\e[0m"
else
echo -e "\e[42mEnter cPanel username:\e[0m"
read -r cpanel_user

echo -e "\e[42mEnter open port:\e[0m"
read -r port

memcached -u "$cpanel_user" -d -m 128 -p "$port"
#Check if Memcached running and confirm
if netstat -napt | grep "$port"
then
echo -e "\e[42mMemcached has been enabled for $cpanel_user on port $port\e[0m" && exit
else
echo -e "\e[42mSomething went wrong\e[0m" && exit
fi
 fi
  fi


if [ "$service" == "redis" ]; then
#Install Epel repo
echo -e "\e[42mInstalling Epel repository\e[0m"
yum install epel-release -y

#Install Redis
echo -e "\e[42mInstalling Redis\e[0m"
wget http://antonrcc.depro7.fcomet.com/remi-release-7.rpm
yum install remi-release-7.rpm -y
yum --enablerepo=remi install redis -y
echo -e "\e[42mInstalling PHP Redis\e[0m"
if grep -i "CentOS" /etc/redhat-release > /dev/null 2>&1; then
no >/dev/null 2>&1 | /opt/cpanel/ea-php56/root/usr/bin/pecl install redis-4.3.0
no >/dev/null 2>&1 | /opt/cpanel/ea-php70/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php71/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php72/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php73/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php74/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php80/root/usr/bin/pecl install redis-5.3.3
no >/dev/null 2>&1 | /opt/cpanel/ea-php81/root/usr/bin/pecl install redis-5.3.3
fi
if grep -i "CloudLinux" /etc/redhat-release > /dev/null 2>&1; then
echo -e "\e[42mIncuding PHP Redis in CageFS\e[0m"
cagefsctl --addrpm redis
echo -e "\e[42mUpdating CageFS skeleton, this will take some time\e[0m"
cagefsctl --force-update
fi

#Enable and start Redis
systemctl enable redis
service redis start

#Check and confirm if Redis running
if redis-cli ping | grep -i "PONG" >/dev/null 2>&1; then
echo -e "\e[42mRedis has been installed on port 6379\e[0m"
else
echo -e "\e[42mSomething went wrong\e[0m"
fi
 fi
  
   
if [ "$service" == "cachewall" ]; then
#Import repo and install Cachewall
echo -e "\e[42mInstalling Cachewall\e[0m"
yum install epel-release -y
pip install virtualenv==15.2.0
rpm -ivh https://repo.cachewall.com/cachewall-release.rpm
yum install cachewall -y
yum install cachewall --enablerepo=cachewall-edge -y

#Input license key and validate
echo -e "\e[42mEnter license key:\e[0m"
read -r license_key

/usr/local/xvarnish/bin/activate --key "$license_key"

#Enable Cachewall
xvctl enable cachewall
xvctl enable https

#Disable xvbeat
mv /usr/bin/xvbeat /usr/bin/xvbeat-old
killall -9 xvbeat

#Restart Cachewall
echo -e "\e[42mRestarting Cachewall\e[0m"

cwctl varnish restart

echo -e "\e[42mCachewall has been installed\e[0m"
fi
if [ "$service" == "elasticsearch" ]; then
#Install Java
echo -e "\e[42mInstalling Java\e[0m"
yum -y install java-1.8.0-openjdk  java-1.8.0-openjdk-devel

#Set JAVA_HOME
echo -e "\e[42mConfiguring JAVA_HOME\e[0m"
cat <<EOF | sudo tee /etc/profile.d/java8.sh
export JAVA_HOME=/usr/lib/jvm/jre-openjdk
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
EOF
source /etc/profile.d/java8.sh

#Add Elasticsearch repo
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo -e "\e[42mCreating Elasticsearch repository\e[0m"
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

#Install Elasticsearch
echo -e "\e[42mInstalling Elasticsearch\e[0m"
yum install --enablerepo=elasticsearch  elasticsearch -y

#Configure TMP dir and start Elasticsearch
echo -e "\e[42mConfiguring Elasticsearch TMP directory\e[0m"
mkdir /usr/share/elasticsearch/tmp
chown elasticsearch: /usr/share/elasticsearch -R
echo "ES_TMPDIR=/usr/share/elasticsearch/tmp" >> /etc/sysconfig/elasticsearch

service elasticsearch start

#Check and confirm if Elasticsearch is running
if curl localhost:9200 | grep -i "You Know, for Search" > /dev/null; then
echo -e "\e[42m Elasticsearch has been installed on port 9200\e[0m"
else
echo -e "\e[42m No curl output. Please run "curl localhost:9200"\e[0m"
fi
 fi
