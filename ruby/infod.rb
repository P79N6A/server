%w{
constants
lambda
names
mime
404
500
audio
blog
cal
code
css
csv
du
edit
facets
feed
filter
find
forum
fs
GET
glob
grep
groonga
HEAD
histogram
html
HTTP
image
index
in
json
kv
ls
mail
man
microblog
out
pager
PATCH
pdf
POST
prototype
rdf
rfc822
ruby
schema
search
sh
text
threads
time
uid
whois
wiki
}.map{|e|require_relative e}
