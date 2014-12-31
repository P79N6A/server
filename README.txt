PW   a webserver which serves a filesystem as RDF or HTML

USE  thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start # run in-place w/o install

INSTALL cd ruby
        bundle install # install dependencies (Rack, RDF.rb)
	./install      # symlink checkout-path to library-path. rsync, cp or build a gem for "release" versions

DAEMON       host         port
 pw        # 0.0.0.0      80 # don't use root to listen on port<1024: setcap cap_net_bind_service=+ep /usr/bin/ruby
 pw local  # 127.0.0.1    80
 pw apache #behind apache 3000
 pw nginx  #behind nginx  3000

SETUP
 mkdir domain/myhostname

CLEANUP
  rm -rf cache # cached RDF-transcodes and image-thumbnails
  rm -rf index # filesystem-based triple-index
  rm -rf address msg # browsable meta-paths for email
