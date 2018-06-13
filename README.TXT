INSTALL install.sh runs out of the box on Termux and gem/bundler/rbenv configs where $sitelibdir is constrained
        to the same uid. outside a sandbox, you can su -c install.sh (to /usr), not rly recommended but it works

	OR add ruby/ to ruby-lib path (install.sh uses a filesystem link) via env-var or RbConfig

	OR build/install a Gem or Bundle. see included Gemfile.

CONFIG within uid-containment + app sandboxing as much as possible, prefer solutions that DO NOT involve
       binding <1024 ports, editing /etc/hosts, or libc-specific LD_PRELOAD DNS-resolver hacks.
       OS/sandbox/kernel config is prefixed with @, app-sandboxed prefixed with $.
       port-numbers in parentheses.

 HTTP (80) bind service
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
      $ unicorn -p 80 .conf/rack.ru

      (80) routing-table
      @ 

      (80) reverse-proxy
      $ mitmdump --showhost -p 80 -m reverse:http://localhost:8000 --set keep_host_header=true

      (8000) local service
      $ unicorn -o localhost -p 8000 .conf/rack.ru

HTTPS (443) SSL frontend
      @ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/python`
      $ mitmdump --showhost -p 443 -m reverse:http://localhost:8000 --set keep_host_header=true

      (8080) proxy port
      $ mitmdump --showhost -m reverse:http://localhost:8000 --set keep_host_header=true
