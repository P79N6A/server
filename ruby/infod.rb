%w{
constants
functions
names
mime
code
css
csv
du
feed
filter
find
fs
glob
grep
groonga
html
image
in
index
json
kv
ls
mail.in
man
out
pager
pdf
rdf
ruby
schema
search
sh
text
}.map{|e|require_relative e}

%w{HTML HTTP}.map{|e| require 'infod/' + e}
