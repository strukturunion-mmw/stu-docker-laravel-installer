FROM nginx:stable-alpine

ADD ./nginx/default.conf /etc/nginx/conf.d/default.conf
ADD ./nginx/nginx-proxy-maxbodysize.conf /etc/nginx/conf.d/maxbodysize.conf

RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN mkdir -p /var/www/html
