# INSTALLATION and USAGE
``` sh
# prerequisites
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config
pacman -S git ruby base-devel graphicsmagick rsync libxml2 libxslt
pkg install autoconf automake binutils clang file findutils git iconv pkg-config python ruby rsync ruby-dev libxslt-dev
xbps-install GraphicsMagick base-devel git ruby ruby-devel rsync libxml2-devel libxslt-devel

git clone https://gitlab.com/ix/pw && cd pw

sh install.sh

unicorn .conf/rack.ru
```
# MIRRORS
[mw.logbook.am](http://mw.logbook.am/src/pw/)
[gitlab.com](https://gitlab.com/ix/pw)
[repo.or.cz](http://repo.or.cz/www)
