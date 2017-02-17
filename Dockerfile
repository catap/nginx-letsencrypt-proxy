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

RUN line="30 2 * * 1 (/usr/bin/letsencrypt renew && /usr/sbin/nginx -s reload) 2>&1 >> /var/log/letsencrypt-renew.log" \
    && (crontab -u root -l 2>/dev/null; echo "$line" ) | crontab -u root -

RUN mkdir -p /var/www/challenges

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-cert-gen.conf /etc/nginx/nginx-cert-gen.conf
COPY nginx.vhost.conf.in /etc/nginx/nginx.vhost.conf.in

EXPOSE 80 443

CMD "/docker-entrypoint.sh"