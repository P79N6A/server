INSTALL sh install.sh OR add source to ruby path OR see Gemfile

USAGE proto port
      HTTP  80    iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080
            8080  unicorn  -p 8080 -o localhost .conf/rack.ru
      HTTPS 443   mitmdump -p  443 -m reverse:http://localhost:8080 --set keep_host_header=true
