#!/bin/sh
cd ruby
ruby install
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
cd ..
mkdir ~/web
ln -sr config/config.ru ~/web
ln -sr config/site.css ~/web/.css
ln -sr config/site.js ~/web/.js
pip install --upgrade pygments
