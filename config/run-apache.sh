#!/bin/sh

if test "$DEBUG"; then
    set -x
fi

. /etc/apache2/envvars

echo Resetting Apache Runtime
rm -rf /run/apache2/* /tmp/httpd* /tmp/apache*
. /usr/local/bin/nsswrapper.sh

/usr/local/bin/lemon-sso.sh
/usr/local/bin/setupvhosts.sh

echo "Starting $APACHE_DOMAIN"
unset APACHE_DOMAIN APACHE_HTTP_PORT PUBLIC_PROTO SSL_INCLUDE OPENLDAP_PROTO \
    OPENLDAP_BIND_DN_PREFIX OPENLDAP_BIND_PW OPENLDAP_CONF_DN_PREFIX \
    OPENLDAP_BASE OPENLDAP_PORT

exec "$@"
