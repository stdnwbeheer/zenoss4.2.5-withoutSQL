# zenoss4.2.5-withoutSQL

Zenoss 4.2.5 on Ubuntu 14.04 base image in a Docker Container without SQL integration.

# Prerequisites
This Dockerfile can only be build with these prerequisites, so you'll need a Docker host. \
docker network create zenoss \
docker run -d -h zenoss4-mysql --name zenoss4-mysql --network zenoss \\
--network-alias zenoss4-mysql -e MYSQL_ROOT_PASSWORD=zenoss mysql:5.5.62

# Usage:
docker build -t "test/zenoss4.2.5-withoutsql:1.0" https://raw.githubusercontent.com/stdnwbeheer/zenoss4.2.5-withoutSQL/master/Dockerfile
