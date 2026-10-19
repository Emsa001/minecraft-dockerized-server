
FROM eclipse-temurin:25-jre-alpine

RUN adduser -D -u 10000 minecraft \
    && mkdir -p /server /data \
    && chown -R minecraft:minecraft /server /data

WORKDIR /server

RUN apk add --no-cache curl \
    && curl -fSL \
       https://meta.fabricmc.net/v2/versions/loader/26.3/0.19.5/1.1.2/server/jar \
       -o /server/fabric.jar \
    && chown minecraft:minecraft /server/fabric.jar \
    && apk del curl
    
COPY --chown=minecraft:minecraft entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER minecraft

EXPOSE 25565/tcp
EXPOSE 24454/udp

ENTRYPOINT ["/server/entrypoint.sh"]