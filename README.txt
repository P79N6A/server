pw(1)   a webserver

USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL cd ruby
        bundle install # depchain
	sh install     # link source to Ruby PATH

DAEMON       host         port
 pw        # 0.0.0.0      80
 pw local  # 127.0.0.1    80
 pw apache # with apache  3000
 pw nginx  # with nginx   3000

WEBSITES  if you've left a bug/complaint on one of these sites and crickets, try emailing <_@whats-your.name> and we'll try to check it
http://src.whats-your.name/pw
https://gitorious.org/element/www
https://github.com/hallwaykid/pw
http://repo.or.cz/w/www.git
