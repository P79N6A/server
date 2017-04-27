this is the webserver that someone on the internet wanted. 

``` sh
git clone https://gitlab.com/ix/pw.git
cd pw/ruby

#debian <http://www.debian.org/>
apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments

#voidlinux <http://www.voidlinux.eu/>
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler

#termux <https://termux.com/>
packages install autoconf automake binutils clang git iconv pkg-config ruby ruby-dev libxslt-dev && gem install bundler

bundle install # ruby dependencies
ruby install   # this
```

see [conf/](conf/) for invocation and configuration for third party utilities like procmail to deliver into a time-based directory structure

for a personal webserver, try domain/localhost as a symlink to a directory synchronized between all your devices via a utility like Syncthing, rsync, or scp

[src.whats-your.name/pw/](http://src.whats-your.name/pw/) [gitlab.com/ix/pw](https://gitlab.com/ix/pw) [repo.or.cz/www](http://repo.or.cz/www)
