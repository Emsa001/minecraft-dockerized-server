#!/bin/sh
cd /data

exec java \
    -Xms512M \
    -Xmx8G \
    -jar /server/fabric.jar \
    nogui