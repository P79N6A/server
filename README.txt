pw  serve POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # dependencies
	./install      # link source to library-path
        cp bin/pw /usr/local/bin

USAGE
 pw            # http - setcap cap_net_bind_service=+ep `which ruby`
 pw ssl        # https
 foreman start # http -> https, https

HOST  mkdir domain/hostname
CLEAN rm -rf cache index
