ARG NGINX_VERSION="1.28.0"

ARG MODSEC_VERSION="3.0.14"
ARG MODSEC_NGINX_VERSION="1.0.4"

ARG LMDB_VERSION="0.9.31"

FROM nginx:${NGINX_VERSION}-bookworm

ARG NGINX_VERSION
ARG MODSEC_VERSION
ARG MODSEC_NGINX_VERSION
ARG LMDB_VERSION

# Install dependencies
RUN apt update -y; \
    apt install -y --no-install-recommends --no-install-suggests \
    automake \
    cmake \
    doxygen \
    g++ \
    git \
    libcurl4-gnutls-dev \
    libfuzzy-dev \
    libmaxminddb-dev \
    liblua5.4-dev \
    libpcre3-dev \
    libpcre2-dev \
    libtool \
    libxml2-dev \
    libyajl-dev \
    make \
    patch \
    pkg-config \
    ruby \
    zlib1g-dev \
    lua-socket \
    gpg

# Install LMDB
RUN set -eux; \
    git clone https://github.com/LMDB/lmdb --branch LMDB_${LMDB_VERSION} --depth 1; \
    make -C lmdb/libraries/liblmdb install

# Install ModSecurity
RUN set -eux; \
    git clone https://github.com/owasp-modsecurity/ModSecurity --branch v${MODSEC_VERSION} --depth 1 --recursive; \
    cd ModSecurity/; \
    ./build.sh; \
    ./configure --with-yajl --with-ssdeep --with-lmdb --with-libmaxminddb --with-pcre2 --enable-silent-rules; \
    make install

# Install ModSecurity-nginx
RUN set -eux; \
    git clone https://github.com/owasp-modsecurity/ModSecurity-nginx.git --branch v${MODSEC_NGINX_VERSION} --depth 1; \
    curl -sSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz; \
    tar -xvzf nginx-${NGINX_VERSION}.tar.gz; \
    cd nginx-${NGINX_VERSION}/; \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx; \
    make modules; \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# Add unicode.mapping
RUN set -eux; \
    mkdir /etc/modsecurity.d; \
    curl -sSL https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/v3/master/unicode.mapping -o /etc/modsecurity.d/unicode.mapping

# Install tools
RUN set -eux; \
    apt install -y curl jq;

# Download OWASP CRS
COPY ./bin/download-latest-crs /usr/local/bin/download-latest-crs
RUN set -eux; \
    chmod +x /usr/local/bin/download-latest-crs; \
    /usr/local/bin/download-latest-crs;

# Download GeoLite2 database
COPY ./bin/download-latest-geolite /usr/local/bin/download-latest-geolite
RUN set -eux; \
    chmod +x /usr/local/bin/download-latest-geolite; \
    /usr/local/bin/download-latest-geolite;

RUN mkdir -p /var/log/nginx;
RUN mkdir -p /var/log/modsecurity;
RUN mkdir -p /var/tmp/nginx;

RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default
COPY ./nginx.conf /etc/nginx/nginx.conf

ENV LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH

EXPOSE 80 443
