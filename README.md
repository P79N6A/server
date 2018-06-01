# PREINSTALL
``` sh
apt-get install git ruby ruby-dev rsync libssl-dev libxml2-dev libxslt1-dev pkg-config
pacman -S graphicsmagick git ruby python-pip base-devel rsync libxml2 libxslt
pkg install graphicsmagick git ruby autoconf automake binutils clang grep file findutils pkg-config ruby-dev libxslt-dev
xbps-install GraphicsMagick base-devel git ruby ruby-devel rsync libxml2-devel libxslt-devel

```
# INSTALL
``` sh
git clone https://gitlab.com/ix/pw ; cd pw
sh install.sh
```
# RUN
``` sh
unicorn .conf/rack.ru
```
# CACHE
``` sh
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
iptables -t nat -I OUTPUT -p tcp -o wlan0 -m owner ! --uid-owner root --dport 443 -j REDIRECT --to-ports 8080
mitmdump --showhost -m reverse:http://localhost:80 --set keep_host_header=true
```
