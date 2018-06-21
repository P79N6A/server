INSTALL sh install.sh OR add source to ruby path OR build+install a Gem/Bundle

USAGE (8000) HTTP    $ unicorn -o localhost -p 8000 .conf/rack.ru
      (8080) HTTPS   $ mitmdump -p 8080 -m reverse:http://localhost:8000 --set keep_host_header=true

      (80)  port map @ iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8000
      (443) port map @ iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 8080
