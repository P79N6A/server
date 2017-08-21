# INSTALL
## dependencies (non-ruby)
``` sh
apt-get install ruby libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments # https://www.debian.org
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments # https://www.voidlinux.eu
packages install autoconf automake binutils clang file findutils git iconv pkg-config ruby ruby-dev libxslt-dev # https://termux.com
```
## dependencies (ruby)
``` sh
cd pw/ruby
./install # link source to library-directory
gem install bundler # install third-party dependencies
bundle config build.nokogiri --use-system-libraries
bundle install
```
# CONFIG (adjust to taste)
``` sh
cd ../.. && mkdir web && cd web # storage
ln ../pw/ruby/config.ru . # server config
ln -s ../pw/{js,css} # CSS and JS
mkdir -p domain/localhost # vhost
```
# RUN
``` sh
unicorn -o 127.0.0.1 -p 8000
```
# MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
