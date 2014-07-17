a general-purpose webserver, focused on minimal-dependency and linked-data

USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL ruby ruby/install
        cp ruby/bin/{R,ww} ~/bin

DAEMON
 ww        # standalone (port 80)
 ww apache # backend to apache (port 3000)
 ww nginx  # backend to nginx (port 3000)
 ww local  # listen only on 127.0.0.1:80

TIPS
 more options in thin --help, and via Rack interface
 if launching outside checkout-dir, symlink {css,js} to use default UI

REQUISITES cd ruby && bundle install

 git://repo.or.cz/www.git            http://repo.or.cz/w/www.git
 git://gitorious.org/element/www.git http://gitorious.org/element
                                     https://github.com/hallwaykid/pw
