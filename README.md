# INSTALL
``` sh
git clone https://gitlab.com/ix/pw

# distro-specific dependency installation
#  https://www.debian.org
apt-get install git ruby ruby-dev libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
#  https://www.voidlinux.eu
xbps-install base-devel git ruby ruby-devel libxml2-devel libxslt-devel python-Pygments
#  https://termux.com
pkg install autoconf automake binutils clang file findutils git iconv pkg-config python ruby ruby-dev libxslt-dev

cd pw && ./install.sh
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
