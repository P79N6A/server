# PREINSTALL
``` sh
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config

pacman -S graphicsmagick git ruby base-devel rsync libxml2 libxslt

pkg install graphicsmagick git ruby autoconf automake binutils clang file findutils iconv pkg-config python rsync ruby-dev libxslt-dev

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
