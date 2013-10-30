%w{
du
filter
find
fs
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
shell
}.map{|e|require_relative 'Es/'+e}
