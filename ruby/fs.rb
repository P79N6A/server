# -*- coding: utf-8 -*-
watch __FILE__
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
      readlink.do{|t|
        mtime = t.mtime.to_i
        yield file, Type, R[Stat+'File']
        yield file, Stat+'mtime', mtime
        yield file, Stat+'size', 0
        t = t.stripDoc
        yield t.uri, Type, Resource
        yield t.uri, Stat+'mtime', mtime
        yield t.uri, Stat+'size', 0}

    else
      resource = stripDoc.uri
      if resource ||= uri
        yield resource, Type, Resource
        yield resource, Stat+'mtime', mtime.to_i
        yield resource, Stat+'size', size
      else
        yield file, Type, R[Stat+'File']
        yield file, Stat+'mtime', mtime.to_i
        yield file, Stat+'size', size
      end
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
    if e.directory?
      e.env[:directory] = true
      s.concat e.c # contained resources
      e.env['REQUEST_PATH'].do{|path| # pagination on day-dirs 
        path.match(/^\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/$/).do{|m|
          t = ::Date.parse "#{m[1]}-#{m[2]}-#{m[3]}"
          pp = (t-1).strftime('/%Y/%m/%d/') # prev day
          np = (t+1).strftime('/%Y/%m/%d/') # next day
          g['#'][Prev] = {'uri' => pp} if pp.R.e || R['//' + e.env['SERVER_NAME'] + pp].e
          g['#'][Next] = {'uri' => np} if np.R.e || R['//' + e.env['SERVER_NAME'] + np].e
          g['#'][Type] = R[HTTP+'Response'] if g['#'][Next] || g['#'][Prev]}}
    end
    s }

  View[Stat+'File'] = -> i,e {
    [(H.once e, 'container', (H.css '/css/container')),
     i.map{|u,r|
       r[Stat+'size'].do{|s|
         {class: :File, title: "#{u}  #{s[0]} bytes",
           c: ["\n", {_: :a, class: :file, href: u, c: '☁'}, # link to file ("download", original MIME)
               "\n", {_: :a, class: :view, href: u.R.stripDoc.a('.html'), c: u.R.abbr}, # link HTML representation of file
               "\n", r[Content], "\n"]}}}]}

  View['ls'] = ->d=nil,e=nil {
    keys = ['uri', Stat+'size', Type, Stat+'mtime']
    rev = e.q.has_key? 'rev'
    sort = e.q['sort'].do{|p|p.expand} || 'uri'
    sortType = ['uri',Type].member?(sort) ? :to_s : :to_i
    {_: :table, class: :ls,
      c: [{_: :tr, c: keys.map{|k| # header
              {_: :th, c: {_: :a, href: e['REQUEST_PATH']+'?view=ls&sort='+k.shorten+(rev ? '' : '&rev=rev'), c: k.R.abbr}}}},
          d.values.sort_by{|v| # sortable
            (v[sort].justArray[0] || 0).send sortType}.send(rev ? :id : :reverse).map{|e|
            {_: :tr, c: keys.map{|k| # body
                {_: :td, property: k, c: k=='uri' ? e.R.href(e[Title] || URI.unescape(e.R.basename)) : e[k].html}}}},
          {_: :style, c: "
table.ls {background-color: #{cs}; color: #000; padding: .3em; margin: .4em;}
table.ls td { white-space: nowrap }
table.ls td[property='uri'] {float: right; font-size: 1.1em; max-width: 32em; overflow: hidden}
.scheme,.abbr {display: none}
table.ls a {text-decoration: none; color: #fff}
table.ls tr:hover {background-color: #000}
"}]}}


  ViewGroup[Stat+'Directory'] = View['ls']
  ViewGroup[Stat+'File']      = View['ls']
  ViewGroup[RDFs+'Resource']  = View['ls']


end
