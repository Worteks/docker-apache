#!/bin/sh

if test "$APACHE_IGNORE_OPENLDAP"; then
    echo Skipping OpenLDAP Configuration - Ignored by Runtime
elif test "$OPENLDAP_HOST" -a "$OPENLDAP_DOMAIN"; then
    APACHE_HTTP_PORT=${APACHE_HTTP_PORT:-8080}
    OPENLDAP_BIND_DN_PREFIX=${OPENLDAP_BIND_DN_PREFIX:-'cn=apache,ou=services'}
    OPENLDAP_BIND_PW=${OPENLDAP_BIND_PW:-'secret'}
    OPENLDAP_CONF_DN_PREFIX=${OPENLDAP_CONF_DN_PREFIX:-'ou=lemonldap,ou=config'}
    OPENLDAP_PROTO=${OPENLDAP_PROTO:-'ldap'}
    if test -z "$OPENLDAP_BASE"; then
	OPENLDAP_BASE=`echo "dc=$OPENLDAP_DOMAIN" | sed 's|\.|,dc=|g'`
    fi
    if test -z "$OPENLDAP_PORT" -a "$OPENLDAP_PROTO" = ldaps; then
	OPENLDAP_PORT=636
    elif test -z "$OPENLDAP_PORT"; then
	OPENLDAP_PORT=389
    fi

    echo -n "Waiting for LDAP backend "
    cpt=0
    while true
    do
	if ldapsearch -H $OPENLDAP_PROTO://$OPENLDAP_HOST:$OPENLDAP_PORT \
		-D "$OPENLDAP_BIND_DN_PREFIX,$OPENLDAP_BASE" \
		-b "ou=users,$OPENLDAP_BASE" \
		-w "$OPENLDAP_BIND_PW" \
		"(objectClass=sweetUser)" >/dev/null 2>&1; then
	    echo " LDAP is alive!"
	    break
	elif test "$cpt" -gt 25; then
	    echo "Could not reach OpenLDAP" >&2
	    exit 1
	fi
	sleep 5
	echo -n .
	cpt=`expr $cpt + 1`
    done

    if test -s /etc/lemonldap-ng/lemonldap-ng.ini; then
	echo Skipping LemonLDAP Configuration - already initialized
    else
	echo "Install LemonLDAP-NG Service Configuration"
	sed -e "s LDAP_PROTO $OPENLDAP_PROTO g" \
	    -e "s LDAP_HOST $OPENLDAP_HOST g" \
	    -e "s LDAP_PORT $OPENLDAP_PORT g" \
	    -e "s|LDAP_SUFFIX|$OPENLDAP_BASE|g" \
	    -e "s|LDAP_CONF_DN_PREFIX|$OPENLDAP_CONF_DN_PREFIX|g" \
	    -e "s|LDAP_BIND_DN_PREFIX|$OPENLDAP_BIND_DN_PREFIX|g" \
	    -e "s|LDAP_BIND_PW|$OPENLDAP_BIND_PW|g" \
	    /usr/share/lemon/etc-lemonldap-ng/lemonldap-ng.ini \
	    >/etc/lemonldap-ng/lemonldap-ng.ini
    fi
else
    echo Skipping OpenLDAP Configuration - no backend defined
fi
