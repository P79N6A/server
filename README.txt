USE     thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL cd ruby
        bundle install # depchain
	sh install     # symlink source to library-path

DAEMON       host         port
 pw        # 0.0.0.0      80
 pw local  # 127.0.0.1    80
 pw apache # with apache  3000
 pw nginx  # with nginx   3000

WEBSITES
http://src.whats-your.name/pw
https://gitorious.org/element/www
https://github.com/hallwaykid/pw
http://repo.or.cz/w/www.git

EXAMPLE
mail http://m.whats-your.name/today/
news http://b.whats-your.name/news/

EMAIL
<mailto:carmen@whats-your.name>
