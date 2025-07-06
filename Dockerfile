ARG NGINX_VERSION="1.27.5"
ARG MODSEC_VERSION="3.0.14"
ARG MODSEC_NGINX_VERSION="1.0.4"
ARG LMDB_VERSION="0.9.31"
ARG PCRE2_VERSION="10.45"
ARG OPENSSL_VERSION="3.0.16"
ARG ZLIB_VERSION="1.3.1"

FROM debian:bookworm-slim AS base

ARG NGINX_VERSION
ARG MODSEC_VERSION
ARG MODSEC_NGINX_VERSION
ARG LMDB_VERSION
ARG PCRE2_VERSION
ARG OPENSSL_VERSION
ARG ZLIB_VERSION

RUN apt update -y

RUN apt install -y --no-install-recommends --no-install-suggests \
    build-essential \
    pkg-config \
    libmaxminddb-dev \
    liblua5.4-dev \
    lua-socket \
    libxml2-dev \
    libyajl-dev \
    libfuzzy-dev \
    libcurl4-gnutls-dev \
    libgeoip-dev \
    wget \
    git \
    ca-certificates \
    libtool \
    autoconf \
    automake

RUN wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz && \
    tar -zxf pcre2-${PCRE2_VERSION}.tar.gz && \
    cd pcre2-${PCRE2_VERSION} && \
    ./configure && \
    make && \
    make install

RUN wget http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar -zxf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure && \
    make && \
    make install

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -zxf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config --prefix=/usr/local --openssldir=/usr/local/ssl && \
    make -j4 && \
    make install

RUN wget https://github.com/LMDB/lmdb/archive/refs/tags/LMDB_${LMDB_VERSION}.tar.gz && \
    tar -zxf LMDB_${LMDB_VERSION}.tar.gz && \
    cd lmdb-LMDB_${LMDB_VERSION}/libraries/liblmdb && \
    make install

RUN git clone https://github.com/owasp-modsecurity/ModSecurity --branch v${MODSEC_VERSION} --depth 1 --recursive && \
    cd ModSecurity && \
    ./build.sh && \
    ./configure --with-yajl --with-ssdeep --with-lmdb --with-libmaxminddb --with-pcre2 --with-lua --enable-silent-rules && \
    make install

RUN wget https://github.com/owasp-modsecurity/ModSecurity-nginx/releases/download/v${MODSEC_NGINX_VERSION}/ModSecurity-nginx-v${MODSEC_NGINX_VERSION}.tar.gz && \
    tar -zxf ModSecurity-nginx-v${MODSEC_NGINX_VERSION}.tar.gz

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/bin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --with-pcre=../pcre2-${PCRE2_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-http_ssl_module \
    --with-stream \
    --with-mail=dynamic \
    --add-dynamic-module=../ModSecurity-nginx-v${MODSEC_NGINX_VERSION} \
    --with-http_ssl_module \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_addition_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads && \
    make && \
    make install

RUN mkdir /etc/modsecurity.d; \
    wget https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/v3/master/unicode.mapping -P /etc/modsecurity.d/unicode.mapping

FROM debian:bookworm-slim
COPY --from=base /usr/bin/nginx /usr/bin/nginx
COPY --from=base /etc/nginx /etc/nginx
COPY --from=base /etc/modsecurity.d /etc/modsecurity.d
COPY --from=base /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=base /usr/local/modsecurity /usr/local/modsecurity
COPY --from=base /usr/local/lib /usr/local/lib
COPY --from=base /usr/local/ssl /usr/local/ssl
COPY --from=base /usr/local/bin /usr/local/bin
COPY --from=base /usr/local/include /usr/local/include
COPY --from=base /usr/local/share /usr/local/share

ENV LD_LIBRARY_PATH="/lib:/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH:-}"

RUN mkdir -p /var/cache/nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /etc/nginx/conf.d

EXPOSE 80 443

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d /etc/nginx/conf.d

CMD ["nginx", "-g", "daemon off;"]
