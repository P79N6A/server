# INSTALL
## System
``` sh
# distro package manager - sorry nixos users, you're on your own
apt-get install ruby libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments                                    # https://www.debian.org
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel python-Pygments                                    # https://www.voidlinux.eu
packages install autoconf automake binutils clang file findutils git iconv pkg-config python ruby ruby-dev libxslt-dev # https://termux.com
# python package manager
pip install pygments
```
## Ruby
``` sh
git clone https://gitlab.com/ix/pw
cd pw/ruby
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install # install all Ruby dependencies
ruby install
```
# CONFIGURE
``` sh
cd ../.. && mkdir web && cd web # storage
ln ../pw/ruby/config.ru . # server config
ln -s ../pw/{js,css} # CSS and JS
```
# RUN
``` sh
unicorn
```
# MIRRORS
[src](http://mw.logbook.am/src/pw/)
[gitlab](https://gitlab.com/ix/pw)
[repo](http://repo.or.cz/www)
