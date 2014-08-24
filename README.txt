

USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL ./ruby/install
        bundle install (if needed)
        cp ruby/bin/{R,ww} ~/bin (optional)

DAEMON       host          port
 ww        # 0.0.0.0      :80
 ww local  # 127.0.0.1    :80
 ww apache # with apache  :3000
 ww nginx  # with nginx   :3000

TIPS
 more options in thin --help, and via Rack interface
 if launching outside checkout-dir, symlink {css,js} for default UI
