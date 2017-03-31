``` sh

apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments

xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler

git clone https://gitlab.com/ix/pw.git

cd pw/ruby

bundle install #dependencies
ruby install   #this

unicorn -rww -o 127.0.0.1 -p 80 --no-default-middleware
thin -rww --threaded -p 80 -a 127.0.0.1 start
```

[src.whats-your.name/pw/](http://src.whats-your.name/pw/) [gitlab.com/ix/pw](https://gitlab.com/ix/pw) [repo.or.cz/www](http://repo.or.cz/www)
