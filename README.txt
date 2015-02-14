POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # dependencies
	./install      # link source to lib-path

USAGE  foreman start # HTTP and HTTPS - see Procfile
                     # don't run as root obviously.. setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
                     # see httpd.ru for other rack servers or behind nginx/apache/lighttpd
HOST  mkdir domain/hostname
CLEAN rm -rf cache index
