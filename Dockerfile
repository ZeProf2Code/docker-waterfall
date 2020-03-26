FROM openjdk:8u131-jre-alpine

VOLUME ["/server", "/plugins", "/config"]
WORKDIR /server

ENV WATERFALL_HOME=/server \
    WATERFALL_BASE_URL=https://papermc.io/api/v1/waterfall/1.15 \
    MEMORY=512m

COPY *.sh /usr/bin/

RUN apk --no-cache add curl bash sudo

EXPOSE 25577

RUN set -x \
	&& addgroup -g 1000 -S waterfall \
	&& adduser -u 1000 -D -S -G waterfall waterfall \
	&& addgroup waterfall wheel

CMD ["/usr/bin/run-waterfall.sh"]
