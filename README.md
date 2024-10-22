# Docker

This is a collection of `Dockerfiles` to build custom images used by Muhammad Zamroi (matriphe).

## Nginx Amplify

The Nginx Amplify using Alpine. Based on [their official repository](https://github.com/nginxinc/docker-nginx-amplify).


## PHP

The PHP fpm image that displays `phpinfo()` as `index.php` file that is useful to check if Nginx works with PHP-fpm.

```console
docker pull ghcr.io/matriphe/docker:php-8.3-fpm-alpine-info
```

### Usage

Make sure to point the `root` directory on Nginx to `/var/www/html`.

Example of Nginx config is the following:

```conf
server {
    listen 80;
    server_name _; # Domain name
    root /var/www/html; # The location of index.php
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
       fastcgi_pass   php:9000; # Update this part
       fastcgi_index  index.php;
       fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
       include        fastcgi_params;
    }
}
```
