%w{
cgi
date
digest/sha1
fileutils
json
nokogiri
open-uri
pathname
rack
shellwords
}.each{|r|require r}
%w{
constants
lambda
mime
404
500
grep
audio
blog
cal
code
csv
edit
facets
feed
forum
fs
GET
graph
groonga
histogram
html
HTTP
image
index
kv
ls
mail
man
microblog
names
POST
postscript
rdf
ruby
schema
text
threads
time
}.map{|e|require_relative e}
