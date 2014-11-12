# coding: utf-8
#watch __FILE__
class R

  ViewGroup[Stat+'Directory'] = ViewGroup[Stat+'File'] = ViewGroup[RDFs+'Resource'] = ->d=nil,e=nil {
    mtime = Stat+'mtime'
    keys = [Stat+'size', 'uri', Type, mtime, LDP+'contains']
    path = e['REQUEST_PATH']
    asc = e.q.has_key? 'asc'
    sort = e.q['sort'].do{|p|p.expand} || mtime
    sortType = [mtime,Stat+'size'].member?(sort) ? :to_i : :to_s
    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)
    up = {_: :a, href: '..', c: '&uarr;', style: 'background-color:#fff;color:#000;margin: 0 .2em .2em 0;padding:0 .11em 0 .11em;float: left;font-size: 2.8em;text-decoration: none'}
    justUp = entries.size == 1 && entries[0].uri == '..'
    justUp && up ||
      [{_: :table, class: :ls,
        c: [{_: :tr, c: keys.map{|k| # header-row
             {_: :th, class: (k == sort ? 'this' : 'that'),
              property: k, c: {_: :a, href: path+'?sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.abbr}}}},
          entries.map{|e|
            types = e.types
            container = types.include?(LDP+'BasicContainer')
            directory = types.include?(Stat+'Directory')
            file = types.include?(Stat+'File')
            re = file ? e.R.stripDoc.a('.html') : e.R
            {_: :tr, uri: re.uri,
             c: keys.map{|k|
               {_: :td, property: k, class: (k == sort ? 'this' : 'that'),
                c: case k
                   when 'uri'
                     (file ? re : e.R).href(e[Label] || e[Title] || URI.unescape(e.R.abbr))
                   when mtime
                     e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                   when Type
                     if directory || container
                       {_: :a, class: :dir, href: e.uri, c: '►'}
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
                       [('<br>' if r.uri.size > 8),
                        r.html
                       ]}.intersperse " "
                   else
                     e[k].html
                   end}}}}]},
     (H.css '/css/ls',true), (H.js '/js/ls',true)]}

end
