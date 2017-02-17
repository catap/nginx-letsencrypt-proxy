#!/bin/bash -e

if [ -z $LETSENCRYPT_EMAIL ]; then
  echo "Missed LETSENCRYPT_EMAIL"
  exit 1
fi

if [ -z $DOMAINS ]; then
  echo "Please setup DOMAINS variable, format: domain.com=backend:1234;domain2.com=backend2:3456"
  exit 1
fi

IFS=';'
ary=($DOMAINS)
for key in "${!ary[@]}"
do
  IFS='='
  sary=(${ary[$key]})
  if [ -z ${sary[1]} ]; then
    echo "Wrong domain setup domain pair \"${ary[$key]}\", expected: domain.com=backend:1234"
    exit 2
  fi
done

IFS=';'
ary=($DOMAINS)
for key in "${!ary[@]}"
do
  IFS='='
  sary=(${ary[$key]})
  if [ ! -d /etc/letsencrypt/live/${sary[0]} ]; then
    nginx -c /etc/nginx/nginx-cert-gen.conf -g 'daemon off;'&
    letsencrypt certonly --rsa-key-size 4096 -a webroot --webroot-path=/var/www/challenges --email $LETSENCRYPT_EMAIL -d ${sary[0]} --text --agree-tos
    kill $(jobs -p)
  fi
done

if [ ! -e /etc/letsencrypt/dhparam.pem ]; then
  openssl dhparam -out /etc/letsencrypt/dhparam.pem 4096
fi

for key in "${!ary[@]}"
do
  IFS='='
  sary=(${ary[$key]})
  if [ -f /etc/nginx/nginx.${sary[0]}.conf.in ]; then
    cat /etc/nginx/nginx.${sary[0]}.conf.in | sed -e "s!@@DOMAIN@@!${sary[0]}!g" | sed -e "s!@@BACKEND@@!${sary[1]}!g" > /etc/nginx/sites-enabled/${sary[0]}
  else
    cat /etc/nginx/nginx.vhost.conf.in | sed -e "s!@@DOMAIN@@!${sary[0]}!g" | sed -e "s!@@BACKEND@@!${sary[1]}!g" > /etc/nginx/sites-enabled/${sary[0]}
  fi
done

/etc/init.d/cron start

nginx -g 'daemon off;'