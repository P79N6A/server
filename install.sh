#!/bin/sh
# install
cd ruby
echo "installing.."
ruby install
echo "\ninstalling dependencies.."
gem install nokogiri -- --use-system-libraries
gem install dimensions
gem install foreman
gem install linkeddata
gem install mail
gem install nokogiri
gem install nokogiri-diff
gem install rack
gem install redcarpet
gem install thin
gem install unicorn
# configure
echo "\nconfiguring server"
cd ../config
mkdir ~/web
ln -sr config.ru ~/web
ln -sr site.css ~/web/.css
ln -sr site.js ~/web/.js
pip install --upgrade pygments
