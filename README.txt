PW   serve a POSIX filesystem as RDF+HTML using HTTP

USAGE  thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start
       unicorn -r./ruby/constants -p 80 ruby/httpd.ru

INSTALL cd ruby
        bundle install # install dependencies (Rack, RDF.rb)
	./install      # symlinks checkout-path to library-path. rsync, cp or build a gem for "release" version

DAEMON       host      port  notes
 pw	     0.0.0.0   80    setcap cap_net_bind_service=+ep `which ruby`
 pw local    127.0.0.1 80    personal webserver
 pw apache   local     3000  see conf/apache.conf for WebID + sendfile config
 pw nginx    local     3000  conf/nginx.conf

SETUP
 mkdir domain/localhost

CLEANUP
  rm -rf cache # cached RDF-transcodes and image-thumbnails
         index # filesystem-based triple-index
         address msg # browsable meta-paths for email
 
