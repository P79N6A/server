USE     thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL cd ruby
        bundle install # depchain
	sh install     # symlink source to library-path

DAEMON       host         port
 pw        # 0.0.0.0      80
 pw local  # 127.0.0.1    80
 pw apache # with apache  3000
 pw nginx  # with nginx   3000

cleanup
  rm -rf cache index

