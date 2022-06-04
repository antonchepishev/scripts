
text/x-generic elasticsearch.sh ( Bourne-Again shell script, ASCII text executable )
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
echo -e "\e[42mCreating Elasticsearch repository\e[0m"
cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/oss-7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

#Install Elasticsearch
echo -e "\e[42mInstalling Elasticsearch\e[0m"
yum -y install elasticsearch-oss

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
echo -e "\e[42m Something went wrong\e[0m"
fi
