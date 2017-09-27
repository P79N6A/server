#!/bin/sh
cd ruby

echo "installing.."
ruby install

cd ../config
echo "\nconfiguring.."
mkdir ~/web
ln -sr config.ru ~/web
ln -sr site.css ~/web/.css
ln -sr site.js ~/web/.js
ln -sr font.woff ~/web/.font.woff

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

pip install --upgrade pygments
