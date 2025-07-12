ARG NGINX_VERSION="1.27.5"
ARG MODSEC_VERSION="3.0.14"
ARG MODSEC_NGINX_VERSION="1.0.4"
ARG LMDB_VERSION="0.9.31"
ARG PCRE2_VERSION="10.45"
ARG OPENSSL_VERSION="3.0.16"
ARG ZLIB_VERSION="1.3.1"
ARG YAJL_VERSION="2.1.0"
ARG GEOIP_VERSION="1.6.12"
ARG LUA_VERSION="5.4.8"
ARG MAXMINDDB_VERSION="1.12.2"
ARG LIBXML2_VERSION="2.14.4"
ARG LIBPLS_VERSION="0.21.5"
ARG LIBCURL_VERSION="8.14.1"
ARG LIBFUZZY_VERSION="2.14.1"

FROM debian:bookworm-slim AS base

ARG NGINX_VERSION
ARG MODSEC_VERSION
ARG MODSEC_NGINX_VERSION
ARG LMDB_VERSION
ARG PCRE2_VERSION
ARG OPENSSL_VERSION
ARG ZLIB_VERSION
ARG YAJL_VERSION
ARG GEOIP_VERSION
ARG LUA_VERSION
ARG MAXMINDDB_VERSION
ARG LIBXML2_VERSION
ARG LIBPLS_VERSION
ARG LIBCURL_VERSION
ARG LIBFUZZY_VERSION

RUN apt update -y

RUN apt install -y --no-install-recommends --no-install-suggests \
    build-essential \
    pkg-config \
    wget \
    git \
    ca-certificates \
    libtool \
    autoconf \
    automake \
    cmake \
    python3 \
    python3-dev \
    binutils

RUN wget https://download.gnome.org/sources/libxml2/${LIBXML2_VERSION%.*}/libxml2-${LIBXML2_VERSION}.tar.xz && \
    tar -xf libxml2-${LIBXML2_VERSION}.tar.xz && \
    cd libxml2-${LIBXML2_VERSION} && \
    ./configure && \
    make check && \
    make install

COPY ./lua-so/Makefile /tmp/Makefile
COPY ./lua-so/src.Makefile /tmp/src.Makefile

RUN wget https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz && \
    tar -zxf lua-${LUA_VERSION}.tar.gz && \
    cd lua-${LUA_VERSION} && \
    cp /tmp/Makefile Makefile && \
    cp /tmp/src.Makefile src/Makefile && \
    make linux test && \
    make install

RUN wget https://github.com/maxmind/geoip-api-c/releases/download/v${GEOIP_VERSION}/GeoIP-${GEOIP_VERSION}.tar.gz && \
    tar -zxf GeoIP-${GEOIP_VERSION}.tar.gz && \
    cd GeoIP-${GEOIP_VERSION} && \
    ./configure && \
    make && \
    make check && \
    make install

RUN wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMINDDB_VERSION}/libmaxminddb-${MAXMINDDB_VERSION}.tar.gz && \
    tar -zxf libmaxminddb-${MAXMINDDB_VERSION}.tar.gz && \
    cd libmaxminddb-${MAXMINDDB_VERSION} && \
    ./configure && \
    make && \
    make check && \
    make install

RUN wget https://github.com/lloyd/yajl/archive/refs/tags/${YAJL_VERSION}.tar.gz -O yajl-${YAJL_VERSION}.tar.gz && \
    tar -zxf yajl-${YAJL_VERSION}.tar.gz && \
    cd yajl-${YAJL_VERSION} && \
    ./configure && \
    make && \
    make install

RUN wget https://github.com/rockdaboot/libpsl/releases/download/${LIBPLS_VERSION}/libpsl-${LIBPLS_VERSION}.tar.gz && \
    tar -zxf libpsl-${LIBPLS_VERSION}.tar.gz && \
    cd libpsl-${LIBPLS_VERSION} && \
    ./configure && \
    make && \
    make check && \
    make install

RUN wget https://github.com/ssdeep-project/ssdeep/releases/download/release-${LIBFUZZY_VERSION}/ssdeep-${LIBFUZZY_VERSION}.tar.gz && \
    tar -zxf ssdeep-${LIBFUZZY_VERSION}.tar.gz && \
    cd ssdeep-${LIBFUZZY_VERSION} && \
    ./configure && \
    make && \
    make install

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

RUN wget https://curl.se/download/curl-${LIBCURL_VERSION}.tar.gz && \
    tar -zxf curl-${LIBCURL_VERSION}.tar.gz && \
    cd curl-${LIBCURL_VERSION} && \
    ./configure --with-openssl && \
    make && \
    make install

RUN wget https://github.com/LMDB/lmdb/archive/refs/tags/LMDB_${LMDB_VERSION}.tar.gz && \
    tar -zxf LMDB_${LMDB_VERSION}.tar.gz && \
    cd lmdb-LMDB_${LMDB_VERSION}/libraries/liblmdb && \
    make install

# It seems like there's a better way to apply the patch for lua 5.4, but for now it's fine.
RUN git clone https://github.com/owasp-modsecurity/ModSecurity --branch v${MODSEC_VERSION} --depth 1 --recursive && \
    cd ModSecurity && \
    sed -i 's/LUA_ERRGCMM/LUA_ERRERR/' src/engine/lua.cc && \
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

RUN cp /lib/x86_64-linux-gnu/libssl* /usr/local/lib/ && \
    cp /lib/x86_64-linux-gnu/libcrypto* /usr/local/lib/

RUN find /usr/local/lib -name "*.so" -exec strip --strip-unneeded {} \; && \
    find /usr/local/lib -name "*.a" -exec rm -f {} \;

RUN find /usr/local/modsecurity/lib -name "*.so" -exec strip --strip-unneeded {} \; && \
    find /usr/local/modsecurity/lib -name "*.a" -exec rm -f {} \;

FROM debian:bookworm-slim
COPY --from=base /usr/bin/nginx /usr/bin/nginx
COPY --from=base /etc/nginx /etc/nginx
COPY --from=base /etc/modsecurity.d /etc/modsecurity.d
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
