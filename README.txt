pw(1)

USAGE   thin --threaded -r./ruby/constants -R ./ruby/httpd.ru -p 80 start

INSTALL cd ruby
        bundle install # dependencies (Rack, RDF)
	sh install     # link source to library-path
        cp ruby/bin/{R,ww} ~/bin # instance-method shell-wrapper + daemon script

DAEMON       host          port
 ww        # 0.0.0.0      :80
 ww local  # 127.0.0.1    :80
 ww apache # with apache  :3000
 ww nginx  # with nginx   :3000

TIPS
 more options in thin --help, and via Rack interface
 if launching outside this dir, symlink {css,js} for default UI
