FROM alpine:latest

LABEL maintainer ianculovici 

ENV TIMEZONE		America/Chicago
ENV DW_VERSION 		2018-04-22a

RUN apk --update add nginx php7 php7-fpm php7-opcache php7-session php7-json php7-pdo_sqlite php7-openssl curl supervisor && \
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone 

COPY nginx-default.conf /etc/nginx/conf.d/default.conf

RUN wget -O /tmp/dokuwiki.tgz https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DW_VERSION}.tgz
RUN cd / && tar xzf /tmp/dokuwiki.tgz && mv dokuwiki-${DW_VERSION} dokuwiki && rm -f /tmp/dokuwiki.tgz

RUN sed -i 's#user = nobody#user = nginx#' /etc/php7/php-fpm.d/www.conf && \
	sed -i 's#group = nobody#group = nginx#' /etc/php7/php-fpm.d/www.conf && \
	mkdir /run/nginx/ && \
	chown -R nginx:nginx /dokuwiki

RUN apk del tzdata && \
	rm -rf /var/cache/apk/*

EXPOSE 80
VOLUME  /dokuwiki
WORKDIR /dokuwiki

COPY supervisord.conf /etc

CMD ["/usr/bin/supervisord"]

