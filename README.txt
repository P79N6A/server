pw  serve POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # dependencies
	./install      # link source to library-path
        cp bin/pw /usr/local/bin # adjust path as appropriate

USAGE
 pw            # http - setcap cap_net_bind_service=+ep `which ruby`
 pw ssl        # https
 foreman start # http -> https, https

HOST mkdir domain/hostname

CLEANUP
  rm -rf cache # cached RDF and thumbnails
         index # fs-backed triple-index and/or other db-stores
