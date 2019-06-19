#!/bin/sh

if test -s /tmp/apache-passwd; then
    echo Skipping nsswrapper setup - already initialized
elif test "`id -u`" -ne 0; then
    echo Setting up nsswrapper mapping `id -u` to www-data
    sed "s|^www-data:.*|www-data:x:`id -g`:|" /etc/group >/tmp/apache-group
    sed \
	"s|^www-data:.*|www-data:x:`id -u`:`id -g`:www-data:/var/www:/usr/sbin/nologin|" \
	/etc/passwd >/tmp/apache-passwd
    export NSS_WRAPPER_PASSWD=/tmp/apache-passwd
    export NSS_WRAPPER_GROUP=/tmp/apache-group
    export LD_PRELOAD=/usr/lib/libnss_wrapper.so
fi
