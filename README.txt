POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # dependencies
	./install      # link source to lib-path

USAGE  foreman start # HTTP and HTTPS - see Procfile
                     # don't run as root. to allow port 80:  setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
                     # see httpd.ru for rack servers and conf/ for nginx/apache/lighttpd
HOST  mkdir domain/hostname
CLEAN rm -rf cache index
