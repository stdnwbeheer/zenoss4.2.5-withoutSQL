#!/bin/bash

# Set variables only if not set.
MYSQLHOST="${MYSQLHOST:=zenoss4-mysql}"
ROOTPW="${ROOTPW:=zenoss}"
USERPW="${USERPW:=zenoss}"
RABBITMQPW="${RABBITMQPW:=zenoss}"
ZENHOME="${ZENHOME:=/usr/local/zenoss}"
ZENOSSHOME="${ZENOSSHOME:=/home/zenoss}"

# RabbitMQ vhost change and zenoss user password change.
rabbitmqctl delete_user zenoss
rabbitmqctl delete_vhost /zenoss
rabbitmqctl add_user zenoss $RABBITMQPW
rabbitmqctl add_vhost /zenoss
rabbitmqctl set_permissions -p /zenoss zenoss '.*' '.*' '.*'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u amqppassword="$RABBITMQPW"'

# Change MYSQL settings in the zenoss global.conf.
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zodb-admin-password="$ROOTPW"'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zep-admin-password="$ROOTPW"'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zodb-password="$USERPW"'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zep-password="$USERPW"'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zodb-host="$MYSQLHOST"'
sudo -H -E -u zenoss bash -c 'export ZENHOME="/usr/local/zenoss" && /usr/local/zenoss/bin/zenglobalconf -u zep-host="$MYSQLHOST"'

# Change MYSQL host and user password setting in zodb_db_main.conf
sed -i "s/localhost/$MYSQLHOST/g" /usr/local/zenoss/etc/zodb_db_main.conf
sed -i "s/passwd zenoss/passwd $USERPW/g" /usr/local/zenoss/etc/zodb_db_main.conf

# Change MYSQL host and user password setting in zodb_db_session.conf
sed -i "s/localhost/$MYSQLHOST/g" /usr/local/zenoss/etc/zodb_db_session.conf
sed -i "s/passwd zenoss/passwd $USERPW/g" /usr/local/zenoss/etc/zodb_db_session.conf

# Import the ZenOSS MySQL files into the MySQL host.
cat <<EOF >> /mysqlsetup.sh
#!/bin/bash
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "create database zenoss_zep"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "create database zodb"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "create database zodb_session"
mysql -uroot -p$ROOTPW -h$MYSQLHOST zenoss_zep < $ZENOSSHOME/zenoss_zep.sql || true
mysql -uroot -p$ROOTPW -h$MYSQLHOST zodb < $ZENOSSHOME/zodb.sql
mysql -uroot -p$ROOTPW -h$MYSQLHOST zodb_session < $ZENOSSHOME/zodb_session.sql
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "CREATE USER 'zenoss'@'localhost' IDENTIFIED BY  '$USERPW';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'localhost' IDENTIFIED BY '$USERPW';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'localhost';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'localhost';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'localhost';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'localhost';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "CREATE USER 'zenoss'@'%' IDENTIFIED BY  '$USERPW';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT REPLICATION SLAVE ON *.* TO 'zenoss'@'%' IDENTIFIED BY '$USERPW';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zodb.* TO 'zenoss'@'%';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zenoss_zep.* TO 'zenoss'@'%';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT ALL PRIVILEGES ON zodb_session.* TO 'zenoss'@'%';"
mysql -uroot -p$ROOTPW -h$MYSQLHOST -e "GRANT SELECT ON mysql.proc TO 'zenoss'@'%';"
EOF
chmod +x /mysqlsetup.sh
/mysqlsetup.sh
exit 0
