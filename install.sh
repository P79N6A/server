#!/bin/sh
# apt install graphicsmagick git ruby ruby-dev libssl-dev libxml2-dev libxslt1-dev
# pkg install graphicsmagick git ruby ruby-dev grep file findutils libxslt-dev
# pacman -S   graphicsmagick git ruby python-pip libxml2 libxslt
cd ruby
ruby install
gem install bundler
pip install --upgrade pygments
bundle install
