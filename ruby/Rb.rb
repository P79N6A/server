# Rb    Rubidium

class Array
  def head; self[0] end
  def tail; self[1..-1] end
  def snd;  self[1] end
  def r; self[rand length] end
  def h; join.h end
  def intersperse i
    inject([]){|a,b|a << b << i}[0..-2]
  end
  def sum
    inject 0, &:+
  end
  def cr
    intersperse "\n"
  end
end

class Hash
  def except *ks
    clone.do{|h|
      ks.map{|k|h.delete k}
      h}
  end
  def has_keys ks; ks.each{|k|
      return false unless has_key? k
    }; true
  end
  def has_any_key ks; ks.each{|k|
      return true if has_key? k
    }; false
  end
end

class Float
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class Fixnum
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class Object
  def id; self end
  def do; yield self end
end

class String
  def h; Digest::SHA1.hexdigest self end
  def hsub h; map{|e|h[e]||e} end
  def map; each_char.map{|l| yield l}.join end
  def tail; self[1..-1] end
  def to_utf8; encode('UTF-8', undef: :replace) end
  def t; match(/\/$/) ? self : self+'/' end
end
class  FalseClass
  def do; nil end
  def to_s; "" end
  alias_method :to_str,:to_s
end

class NilClass
  def do; nil end
  def method_missing f,*a; puts "nil##{f} #{caller[0]}" end
  def to_ary; [] end
  def to_hash; {} end
  def to_s; "" end
  %w{html to_str}.map{|m|alias_method m,:to_s}
end
