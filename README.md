# Nginx with ModSecurity

[![Docker Image CI](https://github.com/meirdev/nginx-modsecurity/actions/workflows/docker-push.yml/badge.svg)](https://github.com/meirdev/nginx-modsecurity/actions/workflows/docker-push.yml)

Minimalist, lightweight (~130MB) Nginx and ModSecurity image, based on Debian Bookworm Slim.

## Usage

```bash
docker run -d -p 80:80 meirdev/nginx-modsecurity
```

## Additional Modules

* ngx_http_js_module
* ngx_http_geoip2_module

## Links

https://github.com/coreruleset/coreruleset

https://github.com/owasp-modsecurity/ModSecurity-nginx

https://github.com/owasp-modsecurity/ModSecurity

https://github.com/P3TERX/GeoLite.mmdb

https://github.com/nginx/njs

https://github.com/leev/ngx_http_geoip2_module

## TODO

- [ ] https://github.com/nginx/nginx-acme
