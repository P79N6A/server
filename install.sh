#!/bin/sh
#base config
# conf=~/web/.conf
# mkdir -p $conf
# rsync -av config/ $conf

# link library to ruby PATH (live install of ruby/)
cd ruby
ruby install

# dependencies
pip install --upgrade pygments
gem install bundler
bundle config build.nokogiri --use-system-libraries
bundle install
