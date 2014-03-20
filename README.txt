USAGE   thin --threaded -r./ruby/HTTP -R ./ruby/httpd.ru -p 80 start

INSTALL ruby ruby/install
        cp ruby/bin/{R,ww} ~/bin

DAEMON
 ww
 ww apache   # backend to apache
 ww nginx    # under nginx
 ww local -d # daemonized on 127.0.0.1

 apache & nginx configs in conf/

REQUISITES cd ruby && bundle install

GIT <https://github.com/hallwaykid/rrww> <https://gitorious.org/element/www>
