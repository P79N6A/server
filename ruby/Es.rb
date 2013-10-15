%w{
filter
find
fs
fsIndex
grep
groonga
in
kv
ls
mime
out
shell
}.map{|e|require_relative 'Es/'+e}
