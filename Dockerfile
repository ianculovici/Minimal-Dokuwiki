FROM alpine:latest

LABEL maintainer ianculovici

ENV TIMEZONE            America/Chicago
ENV DW_VERSION          2020-07-29

RUN apk --update add nginx php7 php7-fpm php7-opcache php7-session php7-json php7-pdo_sqlite php7-openssl curl supervisor && \
        apk add --update tzdata && \
        cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
        echo "${TIMEZONE}" > /etc/timezone

COPY nginx-default.conf /etc/nginx/http.d/default.conf

RUN wget -O /tmp/dokuwiki.tgz https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DW_VERSION}.tgz
RUN cd / && tar xzf /tmp/dokuwiki.tgz && mv dokuwiki-${DW_VERSION} dokuwiki && rm -f /tmp/dokuwiki.tgz

#RUN addgroup -g 907 dokuwiki;
RUN adduser -u 907 -D dokuwiki
RUN sed -i 's#user nginx#user dokuwiki#' /etc/nginx/nginx.conf
RUN sed -i 's#user = nobody#user = dokuwiki#' /etc/php7/php-fpm.d/www.conf && \
        sed -i 's#group = nobody#group = dokuwiki#' /etc/php7/php-fpm.d/www.conf && \
        mkdir -p /run/nginx/ && \
        chown -R dokuwiki:dokuwiki /dokuwiki

RUN apk del tzdata && \
        rm -rf /var/cache/apk/*

EXPOSE 80
VOLUME  /dokuwiki
WORKDIR /dokuwiki

COPY supervisord.conf /etc

CMD ["/usr/bin/supervisord"]
