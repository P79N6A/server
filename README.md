# INSTALLATION and USAGE
``` sh
git clone https://gitlab.com/ix/pw && cd pw
sh install.sh

# dependencies for Debian, Void, Termux
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
xbps-install GraphicsMagick base-devel git ruby ruby-devel rsync libxml2-devel libxslt-devel python-Pygments
pkg install autoconf automake binutils clang file findutils git iconv pkg-config python ruby rsync ruby-dev libxslt-dev

unicorn .conf/rack.ru -p 80
```
# MIRRORS
[mw.logbook.am](http://mw.logbook.am/src/pw/)
[gitlab.com](https://gitlab.com/ix/pw)
[repo.or.cz](http://repo.or.cz/www)
