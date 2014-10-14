watch __FILE__
class R

  View['ls'] = ->d=nil,e=nil {
    mtime = Stat+'mtime'
    keys = [ Stat+'size', Type, 'uri', mtime ]
    path = e['REQUEST_PATH']
    asc = e.q.has_key? 'asc'
    sort = e.q['sort'].do{|p|p.expand} || mtime
    sortType = ['uri',Type].member?(sort) ? :to_s : :to_i
    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)
    entries.unshift({'uri' => '..'}) unless e['REQUEST_PATH']=='/'
    [{_: :table, class: :ls,
       c: [{_: :tr, c: keys.map{|k| # header
               {_: :th, property: k, c: {_: :a, href: path+'?view=ls&sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.abbr}}}},
           entries.map{|e|
             types = e.types
             {_: :tr, class: (e.R.path == path ? 'this' : 'row'),
               c: keys.map{|k| # predicates
                 {_: :td, property: k,
                   c: case k
                      when 'uri'
                        e.R.href(e[Title] || URI.unescape(e.R.basename))
                      when mtime
                        e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                      when Type
                        if types.include?(Stat+'Directory')
                          {_: :a, class: :dir, href: e.uri}
                        elsif types.include?(DC+'Image')
                          ShowImage[e.uri]
                        else
                          e[k].html
                        end
                      else
                        e[k].html
                      end}}}
           }, H.css('/css/ls')]},
    {class: :warp, _: :a, href: e.warp, c: :warp}]}


  ViewGroup[Stat+'Directory'] = View['ls']
  ViewGroup[Stat+'File']      = View['ls']
  ViewGroup[RDFs+'Resource']  = View['ls']

end
