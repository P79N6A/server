USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL ruby ruby/install
        cp ruby/bin/{R,ww} ~/bin

DAEMON
 ww
 ww apache   # backend to apache
 ww nginx    # under nginx
 ww local -d # daemonized on 127.0.0.1

 apache & nginx configs in conf/

REQUISITES cd ruby && bundle install

GIT git://repo.or.cz/www.git            http://repo.or.cz/w/www.git
    git://gitorious.org/element/www.git http://gitorious.org/element
