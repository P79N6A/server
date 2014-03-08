thin --threaded -r./ruby/HTTP -R ./ruby/httpd.ru -p 80 start

INSTALL
ruby ruby/install
cp ruby/{rww,R} ~/bin

DAEMON
  rww apache   # as backend to apache
  rww nginx    # nginx
  rww          # port 80, no frontend
  rww local -d # standalone listening on 127.0.0.1 in background

for apache & nginx see conf/

REQUISITES
cd ruby; bundle install

GIT
https://github.com/hallwaykid/rrww
https://gitorious.org/element/www

NOTE
this server is going away, you probably want <https://github.com/ruby-rdf/rack-linkeddata>
