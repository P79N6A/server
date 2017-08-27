# INSTALL
## System
``` sh
apt-get install git ruby libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments # https://www.debian.org
xbps-install base-devel git ruby ruby-devel libxml2-devel libxslt-devel python-Pygments # https://www.voidlinux.eu
packages install autoconf automake binutils clang file findutils git iconv pkg-config python ruby ruby-dev libxslt-dev # https://termux.com

```
## Python+Ruby
``` sh
git clone https://gitlab.com/ix/pw
cd pw/ruby
gem install bundler
pip install pygments
bundle config build.nokogiri --use-system-libraries
bundle install
ruby install
```
# CONFIGURE
``` sh
cd ../.. && mkdir web && cd web # storage
ln ../pw/ruby/config.ru . # server config
ln -s ../pw/{js,css} # CSS + JS
```
# RUN
``` sh
unicorn
```
# MIRRORS
[mw.logbook.am](http://mw.logbook.am/src/pw/)
[gitlab.com](https://gitlab.com/ix/pw)
[repo.or.cz](http://repo.or.cz/www)
