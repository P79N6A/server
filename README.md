# SOURCE
``` sh
git clone https://gitlab.com/ix/pw.git
cd pw/ruby
```
# INSTALL
## dependencies (distro-specific)
``` sh
#debian <http://www.debian.org/>
apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments

#voidlinux <http://www.voidlinux.eu/>
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler

#termux <https://termux.com/>
packages install autoconf automake binutils clang git iconv pkg-config ruby ruby-dev libxslt-dev && gem install bundler
```
## dependencies (ruby)
``` sh
bundle config build.nokogiri --use-system-libraries
bundle install # third-party libraries
ruby install   # this

```
# CONFIG (adjust to taste)
``` sh
cd ../..
mkdir web && cd web # server-root container
ln -s ../pw/{js,css} # CSS and JS paths
mkdir domain # vhost container
ln -s ~/Sync domain/localhost # host container
ln -s ../pw/conf/config.ru ../pw/conf/unicorn # server config
```
# RUN
``` sh
./unicorn
```


# MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
