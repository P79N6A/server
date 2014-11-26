# coding: utf-8
#watch __FILE__
class R

  ViewGroup[Stat+'Directory'] = ViewGroup[Stat+'File'] = ViewGroup[RDFs+'Resource'] = ->d,env {
    mtime = Stat+'mtime'
    keys = [Stat+'size', 'uri', Type, mtime, LDP+'contains']
    path = env['REQUEST_PATH']
    asc = env.q.has_key? 'asc'
    sort = env.q['sort'].do{|p|p.expand} || mtime
    sortType = [mtime,Stat+'size'].member?(sort) ? :to_i : :to_s
    if d['..']
      d.delete '..'
      up = true
    end
    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)

    [({_: :a, class: :up, href: '..', title: Pathname.new(path).parent.basename, c: '&uarr;'} if up),
     !entries.empty? && {_: :table, class: :ls,
        c: [{_: :tr, c: keys.map{|k| # header-row
             {_: :th, class: (k == sort ? 'this' : 'that'),
              property: k, c: {_: :a, href: path+'?sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.abbr}}}},
          entries.map{|e|
            types = e.types
            container = types.include?(Container)
            directory = types.include?(Stat+'Directory')
            file = types.include?(Stat+'File')
            re = file ? e.R.stripDoc.a('.html') : e.R
            {_: :tr, uri: re.uri,
             c: keys.map{|k|
               {_: :td, property: k, class: (k == sort ? 'this' : 'that'),
                c: case k
                   when 'uri'
                     href = file ? re : e.R
                     {_: :a, href: href.uri,
                      c: e[Label] || e[Title] || (URI.unescape e.R.abbr),
                      style: path==href.path ? "background-color: #bbb" : nil}
                   when mtime
                     e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                   when Type
                     if directory || container
                       {_: :a, class: :dir, href: e.uri, c: '►', style: path==e.R.path ? "color: #bbb" : nil}
                     elsif types.include?(DC+'Image')
                       ShowImage[e.uri]
                     elsif types.size==1 && types[0]==RDFs+'Resource'
                       {_: :a, class: :resource, href: e.uri, c: '■'}
                     elsif file
                       {_: :a, class: :file, href: e.uri, c: '█'}
                     else
                       e[k].html
                     end
                   when LDP+'contains'
                     e[k].justArray.select(&:maybeURI).sort_by{|r|r.uri}.map{|r|
                       large = r.R.basename.size>16 || (r.class == Hash && r[Title])
                       large ? {class: :nowrap, c: r.html} : r.html
                     }.intersperse " "
                   else
                     e[k].html
                   end}}}}]},
     (H.css '/css/ls',true), (H.js '/js/ls',true)]}

end
