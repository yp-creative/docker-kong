# Pull base image
FROM registry.test.com:5000/ubuntu-base:v3

MAINTAINER Baitao Ji, dreambt@gmail.com

ENV KONG_VERSION 0.8.3
ENV YOP_NGINX_INSTALL_DIR /opt

RUN apt-get update
RUN apt-get -y -f install vim git unzip g++ perl
RUN apt-get -y -f install libpcre3=1:8.31-2ubuntu2.3 libpcre3-dev
RUN apt-get -y -f install libuuid1=2.20.1-5.1ubuntu20.7 uuid-dev
RUN apt-get -y -f install libssl1.0.0=1.0.1f-1ubuntu2.21 libssl-dev libmcrypt-dev
RUN apt-get -y -f install libreadline-gplv2-dev libncurses5-dev build-essential luajit

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN git clone git://github.com/yzprofile/ngx_http_dyups_module.git

RUN wget http://openresty.org/download/ngx_openresty-1.9.15.1.tar.gz
RUN tar xzvf ngx_openresty-1.9.15.1.tar.gz
WORKDIR openresty-1.9.15.1
RUN ./configure \
  --with-pcre-jit \
  --with-ipv6 \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --add-module=../ngx_http_dyups_module
RUN make && make install

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN wget http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz
RUN tar xzvf luarocks-2.3.0.tar.gz
WORKDIR luarocks-2.3.0
RUN ./configure \
  --lua-suffix=jit \
  --with-lua=/usr/local/openresty/luajit \
  --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
RUN make -j2 && make build && make install

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN git clone https://github.com/yp-creative/kong.git
WORKDIR kong
RUN git checkout develop
WORKDIR ..
RUN /usr/local/bin/luarocks install kong/kong-0.8.3-0.rockspec --timeout=0
RUN mkdir -p /etc/kong
RUN cp kong/kong-production.yml /etc/kong/kong.yml

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN git clone https://github.com/yp-creative/lua-codec.git
WORKDIR lua-codec/src
RUN make && make install DESTDIR="/usr/local/kong/lib"

ADD mcrypt.so /usr/local/kong/lib/mcrypt.so
WORKDIR $YOP_NGINX_INSTALL_DIR
RUN git clone https://github.com/yp-creative/lua-mcrypt.git
WORKDIR lua-mcrypt
RUN make && make install DESTDIR="/usr/local/kong/lib"

RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/supervisord.conf

EXPOSE 8000 8443 8001 7946

CMD ["/usr/bin/supervisord"]