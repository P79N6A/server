#!/bin/sh
# install
cd ruby
ruby install
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
# configure
cd ../config
mkdir ~/web
ln -sr config.ru ~/web
ln -sr site.css ~/web/.css
ln -sr site.js ~/web/.js
pip install --upgrade pygments
