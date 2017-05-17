# SOURCE
``` sh
git clone https://gitlab.com/ix/pw.git
```
# INSTALL
## dependencies (distro-specific)
``` sh
# debian <http://www.debian.org/>
apt-get install ruby libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments
# void <http://www.voidlinux.eu/>
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
# termux <https://termux.com/>
packages install autoconf automake binutils clang git iconv pkg-config ruby ruby-dev libxslt-dev
```
## dependencies (ruby)
``` sh
cd pw/ruby
gem install bundler # if missing
bundle config build.nokogiri --use-system-libraries
bundle install # third-party libraries
ruby install   # this
cd ../..
```
# CONFIG (adjust to taste)
``` sh
mkdir web && cd web # server-root container
ln -s ../pw/{js,css} # CSS and JS paths
mkdir domain # vhost container
ln -s ~/Sync domain/localhost # host container
ln -s ../pw/conf/{config.ru,unicorn} # server config
```
# RUN
``` sh
./unicorn
```
# MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
