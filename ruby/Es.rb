%w{
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
mail
man
mime
out
pager
pdf
rdf
schema
search
sh
text
}.map{|e|require_relative 'Es/'+e}
