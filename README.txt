POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # dependencies
	./install      # link source to lib-path

USAGE  foreman start # HTTP and HTTPS - see Procfile
                     # nonroot port 80  setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
HOST  mkdir domain/hostname
CLEAN rm -rf cache index
