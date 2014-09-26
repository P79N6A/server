pw(1)   a webserver

USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL cd ruby
        bundle install # install Ruby libraries (Rack, RDF)
	sh install     # link source to Ruby-library-path
        cp bin/* ~/bin # instance-method shell-wrapper and daemon

DAEMON       host         port
 pw        # 0.0.0.0      80
 pw local  # 127.0.0.1    80
 pw apache # with apache  3000
 pw nginx  # with nginx   3000

TIPS
 more daemon options: thin --help
 if launching outside this dir, symlink {css,js} for default UI

MIRRORS
<https://github.com/hallwaykid/pw> <https://gitorious.org/element/www> <http://repo.or.cz/w/www.git>
