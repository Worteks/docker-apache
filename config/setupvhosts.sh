#!/bin/sh

APACHE_DOMAIN=${APACHE_DOMAIN:-'example.com'}
APACHE_HTTP_PORT=${APACHE_HTTP_PORT:-8080}
SSL_INCLUDE=no-ssl
if test -s /etc/apache2/ssl/dhserver-full.crt; then
    echo Skipping Apache SSL configuration - already initialized
    SSL_INCLUDE=do-ssl
elif test -s /var/apache-secret/server.key \
	-a -s /var/apache-secret/server.crt; then
    echo Initializing Apache SSL configuration
    if ! test -s /var/apache-secret/dhparam.pem; then
	echo "No DH found alongside server certificate key pair, generating one"
	echo "This may take some time..."
	openssl dhparam -out /etc/apache2/ssl/dhparam.pem 2048
    else
	ln -sf /var/apache-secret/dhparam.pem /etc/apache2/ssl/
    fi
    if ! test -s /var/apache-secret/ca.crt; then
	cat <<EOT >&2
WARNING: Looks like there is no CA chain defined!
	 assuming it is not required or otherwise included in server
	 certificate definition
EOT
    fi
    cat /var/apache-secret/ca.crt /var/apache-secret/server.crt 2>/dev/null \
	>/etc/apache2/ssl/dhserver-full.crt
    ln -sf /var/apache-secret/server.key /etc/apache2/ssl/
    SSL_INCLUDE=do-ssl
elif test "$PUBLIC_PROTO" = https; then
    SSL_INCLUDE=kindof-ssl
fi
if test -s /etc/apache2/sites-enabled/000-servername.conf; then
    echo Skipping sites-enabled generation - already initialized
else
    echo Initializing sites-enabled
    echo "ServerName $APACHE_DOMAIN" \
	>/etc/apache2/sites-enabled/000-servername.conf
    echo "Listen $APACHE_HTTP_PORT" \
	>/etc/apache2/sites-enabled/001-listen.conf
fi
if test -s /etc/apache2/sites-enabled/003-vhosts.conf; then
    echo Skipping Virtualhosts generation - already initialized
elif test -d /vhosts; then
    echo Installing Custom Virtualhosts
    find /vhosts -name '*.conf' | while read conf
	do
	    sed -e "s|HTTP_PORT|$APACHE_HTTP_PORT|g" \
		-e "s|SSL_TOGGLE_INCLUDE|$SSL_INCLUDE.conf|g" "$conf"
	done >/etc/apache2/sites-enabled/003-vhosts.conf
else
    echo No VirtualHosts templates to install
fi
