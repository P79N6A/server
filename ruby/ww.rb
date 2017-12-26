# coding: utf-8
%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}
%w{URI MIME HTTP HTML POSIX Feed JSON Text Mail Calendar Icons Online}.map{|i|require_relative i}
R = WebResource
class Array
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end
class FalseClass
  def do; self end
end
class NilClass
  def justArray; [] end
  def do; self end
end
class Object
  def justArray; [self] end
  def id; self end
  def do; yield self end
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end
class WebResource
  [MIME,
   HTTP,
   HTML,
   POSIX,
   Feed,
   JSON,
   Webize,
   Util].map{|m|include m}
  module POSIX
    # generally, we prefer hard-links for files which won't be synched to another machine (causing space-waste on remote with naive copy utils),
    # owing to less indirection (notably faster on certain slow-seek media and filesystems) and resilience (not dependent on target-file nonerasure)
    # however Windows and Android (seemingly due to Windows-compat sdcard fs) often fail to support them
    LinkMethod = begin
                   file = '.cache/link'.R
                   link = '.cache/link_'.R
                   file.touch unless file.exist?
                   link.delete if link.exist?
                   file.ln link
                   :ln
                 rescue Exception => e
                   puts e #, e.backtrace
                   :ln_s
                 end
  end
end
