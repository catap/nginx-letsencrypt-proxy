FROM ubuntu:xenial

MAINTAINER Kirill A. Korinsky <kirill@korins.ky>

VOLUME "/etc/letsencrypt"

RUN apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						nginx-light \
            cron \
            openssl \
            letsencrypt \
  && rm -rf /etc/nginx/sites-enabled/default \
	&& rm -rf /var/lib/apt/lists/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

RUN line="30 2 * * 1 /opt/letsencrypt/letsencrypt renew >> /var/log/letsencrypt-renew.log" \
    && (crontab -u root -l 2>/dev/null; echo "$line" ) | crontab -u root -

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vhost.conf.in /etc/nginx/nginx.vhost.conf.in

EXPOSE 80 443

CMD "/docker-entrypoint.sh"