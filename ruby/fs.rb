# -*- coding: utf-8 -*-
class R

  def triplrInode dirChildren=true, &f
    if directory?
      d = descend.uri
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type| yield d, Type, type}
      c.sort.map{|c|c.triplrInode false, &f} if dirChildren

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type| yield uri, Type, type}
      yield uri, Stat+'mtime', Time.now.to_i
      yield uri, Stat+'size', 0
      readlink.do{|t| yield uri, Stat+'target', t.stripDoc}

    else
      yield stripDoc.uri, Type, Resource # generic-resource implied by suffixed-file
      yield uri, Type, R[Stat+'File']
      yield uri, Stat+'size', size
      yield uri, Stat+'mtime', mtime.to_i
    end
  end

  # provide an arg for exceedingly-common case we're reading JSON to return parsed values
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

  alias_method :r, :readFile
  alias_method :w, :writeFile


  def fileResources
    [(self if e), # exact match
     docroot.glob(".*{e,md,n3,ttl,txt}") # docs relative to base
    ].flatten.compact
  end

  FileSet['default'] = -> e,q,g {
    s = []
    s.concat e.fileResources # host-specific paths
    e.justPath.do{|p|        # global paths
      s.concat p.fileResources unless p.uri == '/'}
    s }

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, title: "#{u}  #{s[0]} bytes",
           c: ["\n", {_: :a, class: :file, href: u, c: '☁'}, # link to actual file (download)
               "\n", {_: :a, class: :view, href: u.R.stripDoc.a('.html'), c: u.R.abbr}, # HTML representation of file (via RDF)
               "\n", r[Content], "\n"]}}}]}

  View[Stat+'Link'] = -> i,e {
    i.map{|u,r|
      r[Stat+'target'].do{|t|
        {_: :a, href: t[0].uri, c: t[0].uri}}}}

  View['ls'] = ->d=nil,e=nil {
    keys = ['uri',Stat+'size',Type,Date,Title]
    {_: :table,
      c: [{_: :style, c: ".scheme,.abbr {display: none}"},
          {_: :tr, c: keys.map{|k|{_: :th, c: k.R.abbr}}},
          d.values.map{|e|
            {_: :tr, c: keys.map{|k|
                {_: :td, c: k=='uri' ? e.R.a(e.uri[-1]=='/' ? '?view=ls' : '').href(e.R.abbr) : e[k].html}
              }}}]}}

end
