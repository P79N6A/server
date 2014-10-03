# -*- coding: utf-8 -*-
class R

  def triplrInode &f
    file = URI.escape uri

    if directory?
      d = descend.uri
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type|
        yield d, Type, type}
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type|
        yield file, Type, type}
      yield file, Stat+'mtime', Time.now.to_i
      yield file, Stat+'size', 0
      readlink.do{|t|
        yield file, Stat+'target', t.stripDoc}

    else
      yield file, Type, R[Stat+'File']
      yield file, Stat+'size', size
      yield file, Stat+'mtime', mtime.to_i
    end
  end

  def readFile parseJSON=false
    if f
      if parseJSON
        begin
          JSON.parse File.open(pathPOSIX).read
        rescue Exception => x
          puts "error reading JSON: #{caller} #{uri} #{x}"
          {}
        end
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  rescue Exception => x
    puts x
    self
  end

  alias_method :r, :readFile
  alias_method :w, :writeFile
  alias_method :mk, :mkdir

  def fileResources
    [(self if e), # exact match
     docroot.glob(".*{e,n3,ttl,txt}") # data docs relative to base
    ].flatten.compact
  end

  FileSet['default'] = -> e,q,g {
    s = []
    s.concat e.fileResources
    s.concat e.c if e.directory? && e.uri[-1]=='/'
    s }

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, title: "#{u}  #{s[0]} bytes",
           c: ["\n", {_: :a, class: :file, href: u, c: '☁'}, # link to file ("download", original MIME)
               "\n", {_: :a, class: :view, href: u.R.stripDoc.a('.html'), c: u.R.abbr}, # link HTML representation of file
               "\n", r[Content], "\n"]}}}]}

  View[Stat+'Link'] = -> i,e {}

  View['ls'] = ->d=nil,e=nil {
    keys = ['uri', Stat+'size', Type, Date, Title]
    {_: :table,
      c: [{_: :tr, c: keys.map{|k|{_: :th, c: k.R.abbr}}},
          d.values.map{|e|
            {_: :tr, c: keys.map{|k|
                {_: :td, property: k, c: k=='uri' ? e.R.a(e.uri[-1]=='/' ? '?view=ls' : '').href(URI.unescape e.R.basename) : e[k].html}}}},
          {_: :style, c: ".scheme,.abbr {display: none}\na {text-decoration: none}\ntd[property='uri'] {font-size: 1.18em}"}]}}

end
