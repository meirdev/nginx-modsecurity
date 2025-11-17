# Nginx with ModSecurity

[![Docker Image CI](https://github.com/meirdev/nginx-modsecurity/actions/workflows/docker-push.yml/badge.svg)](https://github.com/meirdev/nginx-modsecurity/actions/workflows/docker-push.yml)

Minimalist, lightweight (~130MB) Nginx, ModSecurity and the OWASP Core Rule Set (CRS) image, based on Debian Bookworm Slim.

## Usage

```bash
docker run -d -p 80:80 meirdev/nginx-modsecurity
```

## Links

https://github.com/coreruleset/coreruleset

https://github.com/owasp-modsecurity/ModSecurity-nginx

https://github.com/owasp-modsecurity/ModSecurity

https://github.com/P3TERX/GeoLite.mmdb

https://github.com/nginx/njs
