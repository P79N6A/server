#!/bin/sh
# install
cd ruby
echo "installing our library.."
ruby install
echo "installing dependencies.."
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
# configure
echo "init server-root"
cd ../config
mkdir ~/web
ln -sr config.ru ~/web
ln -sr site.css ~/web/.css
ln -sr site.js ~/web/.js
pip install --upgrade pygments
