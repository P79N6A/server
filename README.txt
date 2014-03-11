USAGE  thin --threaded -r./ruby/HTTP -R ./ruby/httpd.ru -p 80 start

INSTALL
ruby ruby/install
cp ruby/bin/{R,ww} ~/bin

DAEMON
 ww apache   # backend to apache
 ww nginx    # under nginx
 ww          # port 80, no frontend
 ww local -d # standalone listening on 127.0.0.1 in background

for apache & nginx see conf/

REQUISITES
cd ruby && bundle install

GIT <https://github.com/hallwaykid/rrww> <https://gitorious.org/element/www>
