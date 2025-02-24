ARG NGINX_VERSION="1.27.4"

ARG MODSEC_VERSION="3.0.13"
ARG MODSEC_NGINX_VERSION="1.0.3"

ARG LMDB_VERSION="0.9.31"

ARG CRS_RELEASE="4.11.0"

FROM nginx:${NGINX_VERSION}-bookworm

ARG NGINX_VERSION
ARG MODSEC_VERSION
ARG MODSEC_NGINX_VERSION
ARG LMDB_VERSION
ARG CRS_RELEASE

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
    ./configure --with-yajl --with-ssdeep --with-libmaxminddb --with-pcre2 --enable-silent-rules; \
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

# Download OWASP CRS
RUN curl -sSL https://github.com/coreruleset/coreruleset/releases/download/v${CRS_RELEASE}/coreruleset-${CRS_RELEASE}-minimal.tar.gz -o v${CRS_RELEASE}-minimal.tar.gz; \
    mkdir -p /etc/owasp-crs; \
    tar -zxf v${CRS_RELEASE}-minimal.tar.gz --strip-components=1 -C /etc/owasp-crs; \
    rm -f v${CRS_RELEASE}-minimal.tar.gz; \
    mv -v /etc/owasp-crs/crs-setup.conf.example /etc/owasp-crs/crs-setup.conf

# Download GeoLite2 database
RUN mkdir -p /etc/maxmind; \
    curl -sSL https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb -o /etc/maxmind/GeoLite2-Country.mmdb
