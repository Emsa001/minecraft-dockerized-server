#!/bin/sh
JAR="/server/fabric.jar"

# Heap sizing (safe for your RAM)
MIN_RAM="6G"
MAX_RAM="10G"

# JVM flags optimized for Minecraft (G1GC, low latency)
JAVA_FLAGS="
-Xms${MIN_RAM}
-Xmx${MAX_RAM}
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:G1NewSizePercent=30
-XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=16M
-XX:G1ReservePercent=20
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:MaxTenuringThreshold=1
-Dusing.aikars.flags=false
-Dfile.encoding=UTF-8
"

# Start server
cd /data
exec java $JAVA_FLAGS -jar "$JAR" nogui