# PREINSTALL
``` sh
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config

pacman -S git ruby base-devel graphicsmagick rsync libxml2 libxslt

pkg install autoconf automake binutils clang file findutils git iconv pkg-config python ruby rsync ruby-dev libxslt-dev

xbps-install GraphicsMagick base-devel git ruby ruby-devel rsync libxml2-devel libxslt-devel
```
# INSTALL
``` sh
git clone https://gitlab.com/ix/pw

cd pw

sh install.sh
```
# USE
``` sh
unicorn .conf/rack.ru
```
# MIRRORS
[logbook](http://mw.logbook.am/pw/)
[gitlab](https://gitlab.com/ix/pw)
[repo](http://repo.or.cz/www)
