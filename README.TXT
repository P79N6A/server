INSTALL install.sh runs out of the box on Termux and gem/bundler/rbenv configs where $sitelibdir is constrained
        to the same uid. outside a sandbox, you can su -c install.sh (to /usr), not rly recommended but it works

	OR add ruby/ to ruby-lib path (install.sh uses a filesystem link) via env-var or RbConfig

	OR build/install a Gem or Bundle. see included Gemfile.

CONFIG for support of app sandboxing modern OSes, prefer solutions that DO NOT involve superuser
       favor user-configurable proxy + if-needed DNS server settings

      syntax notes:
       OS/sandbox/kernel config prefixed with @, process spec with $
       port-numbers in parentheses. select one conf-block per port or invent your own

      (80) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp -o lo --dport 80 -j REDIRECT --to-ports 8000

      (80) HTTP daemon
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
      $ unicorn -o localhost -p 80 .conf/rack.ru

      (80) reverse proxy
      $ mitmdump --showhost -p 80 -m reverse:http://localhost:8000 --set keep_host_header=true

      (443) port map via routing-table
      @ iptables -t nat -A OUTPUT -p tcp -o lo --dport 443 -j REDIRECT --to-ports 8080

      (443) HTTPS daemon
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/python`
      $ mitmdump --showhost -p 443 -m reverse:http://localhost:8000 --set keep_host_header=true

      (8000) HTTP daemon
      $ unicorn -o localhost -p 8000 .conf/rack.ru

      (8080) HTTPS proxy
      $ mitmdump --showhost -m reverse:http://localhost:8000 --set keep_host_header=true
