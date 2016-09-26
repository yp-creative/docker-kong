# Pull base image
FROM registry.docker:5000/ubuntu-base:v3

MAINTAINER Baitao Ji, dreambt@gmail.com

ENV KONG_VERSION 0.9.1
ENV YOP_NGINX_INSTALL_DIR /opt

# update source  
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe"> /etc/apt/sources.list  
RUN apt-get update & apt-get upgrade
RUN apt-get -y install vim git unzip gcc perl libpcre3 libpcre3-dev openssl libssl-dev libreadline-gplv2-dev libncurses5-dev uuid-dev build-essential luajit

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
RUN git clone https://github.com/yp-creative/lua-codec.git
WORKDIR lua-codec/src
RUN make && make install DESTDIR="/usr/local/kong/lib"

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN git clone https://github.com/yp-creative/lua-mcrypt.git
WORKDIR lua-mcrypt
RUN make && make install DESTDIR="/usr/local/kong/lib"

WORKDIR $YOP_NGINX_INSTALL_DIR
RUN mkdir -p /etc/kong
RUN git clone https://github.com/yp-creative/kong.git && cd kong && git checkout develop && cd .. && /usr/local/bin/luarocks install kong/kong-0.8.3-0.rockspec
COPY kong/kong-production.yml /etc/kong/kong.yml

ADD nginx /home/nginx

EXPOSE 8000 8443 8001 7946

CMD ["kong", "start"]
