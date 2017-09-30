#!/bin/sh
echo "installing.."
./ruby/install

cd config
echo "\nconfiguring.."
mkdir ~/web
cp config.ru ~/web
cp site.css ~/web/.css
cp site.js ~/web/.js
cp font.woff ~/web/.font.woff

echo "\ninstalling Ruby dependencies.."
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
