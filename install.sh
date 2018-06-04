#!/bin/sh

# this
cd ruby
ruby install

# dependencies

# apt install  graphicsmagick git ruby pkg-config ruby-dev libssl-dev libxml2-dev libxslt1-dev
# pkg install  graphicsmagick git ruby pkg-config ruby-dev autoconf automake binutils clang grep file findutils libxslt-dev
# pacman -S    graphicsmagick git ruby base-devel python-pip libxml2 libxslt
# xbps-install GraphicsMagick git ruby base-devel ruby-devel libxml2-devel libxslt-devel

pip install --upgrade pygments
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
