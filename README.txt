pw  serve POSIX filesystem <> RDF+HTML <> HTTP

INSTALL cd ruby
        bundle install # install missing dependencies
	./install      # link source to library-path
        cp bin/pw /usr/local/bin # adjust path as appropriate

USAGE
 pw            # http - setcap cap_net_bind_service=+ep `which ruby`
 pw ssl        # https
 foreman start # http -> https, https

SETUP
 mkdir domain/localhost

CLEANUP
  rm -rf cache # cached RDF and thumbnails
         index # fs-backed triple-index and/or other DB storage-files
 
