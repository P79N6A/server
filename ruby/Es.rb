%w{
filter
find
fs
fs.index
grep
groonga
in
kv
ls
mime
out
shell
}.map{|e|require_relative 'Es/'+e}
