# INSTALL
``` sh
git clone https://gitlab.com/ix/pw && cd pw

## platform dependencies:
#Debian https://www.debian.org
apt-get install git ruby ruby-dev libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
#Void https://www.voidlinux.eu
xbps-install base-devel git ruby ruby-devel libxml2-devel libxslt-devel python-Pygments
#Termux https://termux.com
pkg install autoconf automake binutils clang file findutils git iconv pkg-config python ruby ruby-dev libxslt-dev

sh install
```
# RUN
``` sh
unicorn .conf/rack.ru -p 80
```
# MIRRORS
[mw.logbook.am](http://mw.logbook.am/src/pw/)
[gitlab.com](https://gitlab.com/ix/pw)
[repo.or.cz](http://repo.or.cz/www)
