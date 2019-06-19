# SweetApache

Generic Apache image running Sweet services.

Build with:
```
$ make build
```

Test with:
```
$ make run
```

Build in OpenShift:

```
$ make ocbuild
```

Cleanup OpenShift assets:

```
$ make ocpurge
```

Environment variables and volumes
----------------------------------

The image recognizes the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker `run` command.

|    Variable name           |    Description            | Default                                                            |
| :------------------------- | ------------------------- | ------------------------------------------------------------------ |
|  `APACHE_DOMAIN`           | Apache ServerName         | `example.com`                                                      |
|  `APACHE_IGNORE_OPENLDAP`  | Ignore LemonLDAP autoconf | undef                                                              |
|  `APACHE_HTTP_PORT`        | Apache Listen Port        | `8080`                                                             |
|  `OPENLDAP_BASE`           | OpenLDAP Base             | seds `OPENLDAP_DOMAIN`, `example.com` produces `dc=example,dc=com` |
|  `OPENLDAP_BIND_DN_RREFIX` | OpenLDAP Bind DN Prefix   | `cn=apache,ou=services`                                            |
|  `OPENLDAP_BIND_PW`        | OpenLDAP Bind Password    | `secret`                                                           |
|  `OPENLDAP_CONF_DN_RREFIX` | OpenLDAP Conf DN Prefix   | `cn=lemonldap,ou=config`                                           |
|  `OPENLDAP_DOMAIN`         | OpenLDAP Domain Name      | undef                                                              |
|  `OPENLDAP_HOST`           | OpenLDAP Backend Address  | undef                                                              |
|  `OPENLDAP_PORT`           | OpenLDAP Bind Port        | `389` or `636` depending on `OPENLDAP_PROTO`                       |
|  `OPENLDAP_PROTO`          | OpenLDAP Proto            | `ldap`                                                             |
|  `PUBLIC_PROTO`            | Apache Public Proto       | `http`                                                             |

|  Volume mount point                     | Description                                                                     |
| :-------------------------------------- | ------------------------------------------------------------------------------- |
|  `/var/apache-secrets`                  | Apache Secrets root - install server.crt, server.key and ca.crt to enable https |
|  `/vhosts`                              | Apache VirtualHosts templates root - processed during container start           |
