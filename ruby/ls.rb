#watch __FILE__
class R

  View['ls'] = ->d=nil,e=nil {
    mtime = Stat+'mtime'
    keys = [ Stat+'size', Type, 'uri', mtime ]
    path = e['REQUEST_PATH']
    asc = e.q.has_key? 'asc'
    sort = e.q['sort'].do{|p|p.expand} || mtime
    sortType = ['uri',Type].member?(sort) ? :to_s : :to_i
    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)
    entries.unshift({'uri' => '../'}) unless e['REQUEST_PATH']=='/'

    [{_: :table, class: :ls,
       c: [{_: :tr, c: keys.map{|k| # header row
               {_: :th, property: k, c: {_: :a, href: path+'?view=ls&sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.abbr}}}},
           entries.map{|e| # body rows
             types = e.types
             directory = types.include?(Stat+'Directory')
             file = types.include?(Stat+'File')
             re = file ? e.R.stripDoc.a('.html') : e.R
             {_: :tr, uri: re.uri, class: (e.R.path == path ? 'this' : 'row'),
               c: keys.map{|k| # predicates
                 {_: :td, property: k,
                   c: case k
                      when 'uri'
                        (file ? re : e.R).href(e[Title] || URI.unescape(e.R.basename))
                      when mtime
                        e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                      when Type
                        if directory
                          {_: :a, class: :dir, href: e.uri}
                        elsif types.include?(DC+'Image')
                          ShowImage[e.uri]
                        elsif file
                          {_: :a, class: :file, href: e.uri}
                        else
                          e[k].html
                        end
                      else
                        e[k].html
                      end}}}
           }, H.css('/css/ls',true),(H.js '/js/ls',true)
          ]},
    {class: :warp, _: :a, href: e.warp}]}


  ViewGroup[Stat+'Directory'] = View['ls']
  ViewGroup[Stat+'File']      = View['ls']
  ViewGroup[RDFs+'Resource']  = View['ls']

end
