INSTALL install.sh to link source path in $sitelibdir

	OR add source to ruby library path via shell-env or RbConfig variable

	OR build/install a Gem or Bundle. see included Gemfile.

CONFIG
      @ = OS/sandbox/kernel config
      $ = process spec

      (80) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8000

      (80) HTTP
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
      $ unicorn -o localhost -p 80 .conf/rack.ru

      (80) HTTP proxy
      $ mitmdump -p 80 -m reverse:http://localhost:8000 --set keep_host_header=true

      (443) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 8080

      (443) HTTPS
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/python`
      $ mitmdump -p 443 -m reverse:http://localhost:8000 --set keep_host_header=true

      (8000) HTTP daemon
      $ unicorn -o localhost -p 8000 .conf/rack.ru

      (8080) HTTPS proxy
      $ mitmdump -m reverse:http://localhost:8000 --set keep_host_header=true
