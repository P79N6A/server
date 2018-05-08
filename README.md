# DEPEND
``` sh
# termux
pkg install graphicsmagick git ruby autoconf automake binutils clang grep file findutils iconv pkg-config python rsync ruby-dev libxslt-dev

# debian
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config

# arch
pacman -S graphicsmagick git ruby python-pip base-devel rsync libxml2 libxslt

# void
xbps-install GraphicsMagick base-devel git ruby ruby-devel rsync libxml2-devel libxslt-devel

```
# INSTALL
``` sh
git clone https://gitlab.com/ix/pw ; cd pw
sh install.sh
```
# USE
``` sh
unicorn .conf/rack.ru
```
# DEVELOP
``` sh
setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/ruby`
DEV=1 unicorn .conf/rack.ru -p 80
```
# PROXY
``` sh
setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/python3`
mitmproxy -p 443 --showhost -m reverse:http://localhost --set keep_host_header=true
```
# CERTIFY
``` sh
cd ~/.mitmproxy/
openssl x509 -inform PEM -subject_hash_old -in mitmproxy-ca-cert.pem
ln mitmproxy-ca-cert.pem /android/system/etc/security/cacerts/c8750f0d.0 # adjust to match hash output above
```
# MIRROR
[logbook](http://mw.logbook.am/pw/)
[gitlab](https://gitlab.com/ix/pw)
[repo](http://repo.or.cz/www)
