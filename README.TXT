INSTALL sh install.sh OR add source to ruby path OR build+install a Gem/Bundle

USAGE  @ = OS/sandbox/kernel config
       $ = process spec

      (80) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8000

      (443) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 8888

      (8000) HTTP daemon
      $ unicorn -o localhost -p 8000 .conf/rack.ru

      (8888) HTTPS proxy
      $ mitmdump -m reverse:http://localhost:8000 --set keep_host_header=true
