%w{
du
filter
find
fs
glob
grep
groonga
in
index
kv
ls
man
mime
out
rdf
sh
}.map{|e|require_relative 'Es/'+e}
