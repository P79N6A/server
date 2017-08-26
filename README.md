# INSTALL
## non-ruby
``` sh
# distro package manager - sorry nixos users, you're on your own
apt-get install ruby libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments                                    # https://www.debian.org
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel python-Pygments                                    # https://www.voidlinux.eu
packages install autoconf automake binutils clang file findutils git iconv pkg-config python ruby ruby-dev libxslt-dev # https://termux.com
# python package manager
pip install pygments
```
## ruby
``` sh
git clone https://gitlab.com/ix/pw
cd pw/ruby
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
ruby install
```
# CONFIGURE
``` sh
cd ../.. && mkdir web && cd web # storage
ln ../pw/ruby/config.ru . # server config
ln -s ../pw/{js,css} # CSS and JS
mkdir -p domain/localhost # vhost
```
# RUN
``` sh
unicorn
```
# MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
