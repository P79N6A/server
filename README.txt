pw  serve POSIX filesystem <> RDF+HTML <> HTTP

RUN thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start
    unicorn -r./ruby/constants -p 80 ruby/httpd.ru

INSTALL cd ruby
        bundle install # install missing dependencies
	./install      # link code to library-path (rsync, cp or build a gem for a "release"..)

DAEMON       host      port  notes
 pw	     0.0.0.0   80    setcap cap_net_bind_service=+ep `which ruby`
 pw local    localhost 80    personal webserver
 pw apache   localhost 3000  conf/apache.conf
 pw nginx    localhost 3000  conf/nginx.conf

 unicorn -rww -p 80 /src/pw/ruby/httpd.ru

SETUP
 mkdir domain/localhost

CLEANUP
  rm -rf cache # cached RDF and thumbnails
         index # fs-backed triple-index and/or other DB storage-files
 
