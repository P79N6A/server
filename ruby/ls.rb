# coding: utf-8
#watch __FILE__
class R

  View['ls'] = ->d=nil,e=nil {
    mtime = Stat+'mtime'
    keys = [ Stat+'size', 'uri', Type, mtime, LDP+'contains' ]
    path = e['REQUEST_PATH']
    asc = e.q.has_key? 'asc'
    sort = e.q['sort'].do{|p|p.expand} || mtime
    sortType = [mtime,Stat+'size'].member?(sort) ? :to_i : :to_s
    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)

    [{_: :table, class: :ls,
       c: [{_: :tr, c: keys.map{|k| # header row
              {_: :th, class: (k == sort ? 'this' : 'that'),
               property: k, c: {_: :a, href: path+'?sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.fragment || k.R.basename}}}},
           entries.map{|e| # entries
             types = e.types
             directory = types.include?(Stat+'Directory')
             file = types.include?(Stat+'File')
             re = file ? e.R.stripDoc.a('.html') : e.R
             {_: :tr, uri: re.uri,
               c: keys.map{|k|
                 {_: :td, property: k, class: (k == sort ? 'this' : 'that'),
                   c: case k
                      when 'uri'
                        (file ? re : e.R).href(e[Title] || URI.unescape(e.R.basename))
                      when mtime
                        e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                      when Type
                        if directory
                          {_: :a, class: :dir, href: e.uri, c: '►'}
                        elsif types.include?(DC+'Image')
                          ShowImage[e.uri]
                        elsif types.size==1 && types[0]==RDFs+'Resource'
                          {_: :a, class: :resource, href: e.uri, c: '■'}
                        elsif file
                          {_: :a, class: :file, href: e.uri}
                        else
                          e[k].html
                        end
                      when LDP+'contains'
                        e[k].justArray.map(&:maybeURI).map{|r|
                          r && [
                            (r.size > 32 ? '<br>' : ''),
                            r.R.href,' ',
                           ]}
                      else
                        e[k].html
                      end}}}}]},
     (H.css '/css/ls', true),
     (H.js '/js/ls', true),
     ({_: :style, c: "table.ls {width: 100%}"} if e.q['view']=='ls'),
     {class: :warp, _: :a, href: e.warp, c: '/'},
     {_: :a, href: e.uri + '?view=tabulate', c: {_: :img, src: '/css/misc/cube.png'},
     }]}


  ViewGroup[Stat+'Directory'] = View['ls']
  ViewGroup[Stat+'File']      = View['ls']
  ViewGroup[RDFs+'Resource']  = View['ls']

end
