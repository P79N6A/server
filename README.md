USE

thin --threaded -r./ruby/HTTP -R ./ruby/httpd.ru -p 80 start

INSTALL

ruby ruby/install
cp ruby/rww ~/bin

DAEMON

  rww apache   # as backend to apache
  rww nginx    # nginx
  rww          # port 80, no frontend
  rww local -d # standalone listening on 127.0.0.1 in background

for apache & nginx see conf/

REQUISITES
cd ruby; bundle install
