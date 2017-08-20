# INSTALL
## dependencies
``` sh
# debian http://www.debian.org/
apt-get install ruby libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments

# void   http://www.voidlinux.eu/
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments

# termux https://termux.com/
packages install autoconf automake binutils clang file findutils git iconv pkg-config ruby ruby-dev libxslt-dev
```
## dependencies (ruby)
``` sh
cd pw/ruby
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
ruby install
cd ../..
```
# CONFIG (adjust to taste)
``` sh
mkdir web && cd web # server container
ln ../pw/ruby/config.ru . # server config
ln -s ../pw/{js,css} # CSS and JS containers
mkdir -p domain/localhost # vhost container
```
# RUN
``` sh
unicorn -o 127.0.0.1 -p 8000
```
# MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
