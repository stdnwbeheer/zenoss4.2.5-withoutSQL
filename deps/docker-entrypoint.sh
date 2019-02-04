#!/bin/bash

#Stop container procedure
cleanup() {
    echo "Container stopped, performing cleanup..."
    /etc/init.d/zenoss stop && sleep 2
    /etc/init.d/mysql stop && sleep 2
    /etc/init.d/rabbitmq-server stop && sleep 2
    /etc/init.d/redis-server stop && sleep 2
    /etc/init.d/memcached stop
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

#Start container procedure
/etc/init.d/memcached start && sleep 2
/etc/init.d/redis-server start && sleep 2
/etc/init.d/rabbitmq-server start && sleep 2
if [ ! -f /firstrun.done ]; then
    /firstrun.sh
    touch /firstrun.done
fi
/etc/init.d/zenoss start && sleep 5
tail -f /dev/null &

#Wait
wait $!
