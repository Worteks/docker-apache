FROM debian:stretch-slim

# Apache Base image for OpenShift Origin

LABEL io.k8s.description="Apache 2.4 Base Image." \
      io.k8s.display-name="Apache 2.4" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="apache,httpd,apache2,apache24" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/Worteks/docker-apache" \
      maintainer="Thibaut DEMARET <thidem@worteks.com>, Samuel MARTIN MORO <sammar@worteks.com>" \
      version="2.4"

ENV DEBIAN_FRONTEND=noninteractive \
    DI=https://github.com/Yelp/dumb-init/releases/download/ \
    DUMBINITVERSION=1.2.2

COPY config/* /

RUN echo "# Install Dumb-init" \
    && apt-get update \
    && apt-get -y install wget \
    && wget $DI/v${DUMBINITVERSION}/dumb-init_${DUMBINITVERSION}_amd64.deb \
	-O dumb-init.deb \
    && dpkg -i dumb-init.deb \
    && apt-get install -f -y \
    && if test "$DO_UPGRADE"; then \
	echo "# Upgrade Base Image"; \
	apt-get -y upgrade; \
	apt-get -y dist-upgrade; \
    fi \
    && if test "$DEBUG"; then \
	echo "# Install Debugging Tools" \
	&& apt-get -y install vim ldap-utils; \
    else \
	apt-get -y remove --purge wget; \
    fi \
    && echo "# Install Apache" \
    && apt-get install --no-install-recommends -y ca-certificates apache2 \
	libnss-wrapper ldap-utils libmodule-build-perl libapache2-mod-perl2 libcgi-pm-perl \
	libapache-session-ldap-perl lemonldap-ng-handler \
    && apt-get -y remove --purge libapache-session-browseable-perl \
    && ( \
	echo y; \
	echo o conf prerequisites_policy follow; \
	echo o conf commit \
    ) | cpan install \
	Apache::Session::Browseable \
	Apache::Session::Browseable::LDAP \
	Apache::Session::Browseable::Store::LDAP \
    && mkdir -p /usr/share/lemon/etc-lemonldap-ng \
    && mv /lemonldap-ng.ini /usr/share/lemon/etc-lemonldap-ng/ \
    && apt-get clean \
    && . /etc/apache2/envvars \
    && ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log" \
    && ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log" \
    && ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log" \
    && sed -i '/[Ii]nclude.*ports.conf/d' /etc/apache2/apache2.conf \
    && if grep ErrorLog /etc/apache2/apache2.conf >/dev/null; then \
	sed -i 's|ErrorLog.*|ErrorLog /dev/stderr|' /etc/apache2/apache2.conf; \
    else \
	echo ErrorLog /dev/stderr >>/etc/apache2/apache2.conf; \
    fi \
    && if grep TransferLog /etc/apache2/apache2.conf >/dev/null; then \
	sed -i 's|TransferLog.*|TransferLog /dev/stdout|' /etc/apache2/apache2.conf; \
    else \
	echo TransferLog /dev/stdout >>/etc/apache2/apache2.conf; \
    fi \
    && if test "$DEBUG"; then \
	sed -i 's|LogLevel warn|LogLevel debug|' /etc/apache2/apache2.conf; \
    fi \
    && mkdir -p /vhosts \
    && mv /status.conf /vhosts/99-status.conf \
    && mv /do-ssl.conf /no-ssl.conf /kindof-ssl.conf /etc/apache2/ \
    && mv /custom-log-fmt.conf /remoteip.conf /etc/apache2/conf-available/ \
    && a2enmod alias remoteip rewrite ssl headers perl status \
    && a2enconf remoteip custom-log-fmt \
    && mv /lemon-sso.sh /nsswrapper.sh /setupvhosts.sh /usr/local/bin/ \
    && cp -p /etc/lemonldap-ng/lemonldap-ng.ini \
	/root/original-lemonldap-ng.ini \
    && for dir in "$APACHE_LOCK_DIR" "$APACHE_RUN_DIR" \
	/var/www/html /etc/apache2/sites-enabled /etc/lemonldap-ng; \
	do \
	    rm -rvf "$dir" \
	    && mkdir -p "$dir" \
	    && chmod a+rwx -R "$dir"; \
	done \
    && echo "Apache OK" >/var/www/html/index.html \
    && chmod 666 /var/www/html/index.html \
    && chmod a+rwx -R /run "$APACHE_LOG_DIR" \
    && rm -rf /etc/apache2/ports.conf /usr/share/man /usr/share/doc \
	/etc/apache2/sites-enabled/*default* dumb-init.deb \
    && unset HTTP_PROXY HTTPS_PROXY NO_PROXY DO_UPGRADE http_proxy https_proxy

USER 1001
WORKDIR /var/www/html
ENTRYPOINT ["dumb-init","--","/run-apache.sh"]
CMD "/usr/sbin/apache2ctl" "-D" "FOREGROUND"
