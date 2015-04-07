# coding: utf-8
#watch __FILE__
class R

  # POSTable container -> contained types
  Containers = {
    Wiki => SIOCt+'WikiArticle',
    Forum            => SIOC+'Thread',
    SIOC+'Thread'    => SIOCt+'BoardPost',
   SIOCt+'BoardPost' => SIOCt+'BoardPost',
  }

  Filter[Container] = -> g,e { # summarize a container
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # RDF types
        if v = Abstract[type] # summarizer
          groups[v] ||= {} # type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # summarize

  TabularView = ViewGroup[Container] = ViewGroup[CSVns+'Row'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq - [Label]
    keys = keys - [SIOC+'has_container'] if e.R.path == '/'
    sort = (e.q['sort']||'uri').expand
    direction = e.q.has_key?('reverse') ? :reverse : :id
    sizes = g.values.map{|r|r[Size]}.flatten.compact
    e[:max] = size = sizes.max
    e[:scale] = 255.0 / (size && size > 0 && size || 255).to_f
    [H.css('/css/table',true), H.css('/css/container',true), "\n",
     {_: :table, :class => :tab,
      c: [{_: :tr,
           c: keys.map{|k|
             this = sort == k
             q = e.q.merge({'sort' => k.shorten})
             if direction == :reverse
               q.delete 'reverse'
             else
               q['reverse'] = ''
             end
             [{_: :th, property: k, class: this ? :this : :that,
               c: {_: :a, rel: :nofollow, href: CGI.escapeHTML(q.qs),
                   class: case k
                          when LDP+'contains'
                            :container
                          when Size
                            :size
                          when Mtime
                            :time
                          when 'uri'
                            :id
                          else
                            ''
                          end,
                   c: case k
                      when Type
                        {_: :img, src: '/css/misc/cube.svg'}
                      when SIOC+'has_container'
                        '&uarr;'
                      when 'uri'
                        ''
                      when LDP+'contains'
                        ''
                      when Size
                        ''
                      when Mtime
                        ''
                      else
                        k.R.abbr
                      end
                  }}, "\n"]}}, "\n",
          g.resources(e).send(direction).map{|row|
            TableRow[row,e,sort,direction,keys]}]}, "\n"]}

  ViewA[Container] = -> r, e, sort, direction {
    re = r.R
    uri = re.uri
    path = (re.path||'').t
    group = e.q['group']
    {class: :container,
     c: r[LDP+'contains'].do{|c|
       sizes = c.map{|r|r[Size] if r.class == Hash}.flatten.compact
       maxSize = sizes.max
       sized = !sizes.empty? && maxSize > 1
       width = maxSize.to_s.size
       c.sortRDF(e).send(direction).map{|r|
         data = r.class == Hash
         [{_: :a, href: r.R.uri, class: :member,
           c: [(if data && sized && r[Size]
                s = r[Size].justArray[0]
                [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                end),
               ([r[Date].justArray[0].to_s,' '] if data && sort==Date),
               data && CGI.escapeHTML((r[Title] || r[Label] || r.R.fragment || r.R.basename).justArray[0].to_s) || r.R.abbr[0..64]
              ]}, data ? "<br>" : " "]}}}}

  Icons = {
    Container => :dir,
    Directory => :warp,
    FOAF+'Person' => :person,
    GraphDoc => :graph,
    Resource => :graph,
    Image => :img,
    SIOC+'Thread' => :thread,
    SIOC+'Usergroup' => :group,
    Stat+'File' => :file,
    '#editable' => :scissors,
  }

  TableRow = -> l,e,sort,direction,keys {
    mag = l[Size].justArray[0].do{|s|s * e[:scale]} || 0
    c = '%02x' % (255 - mag)
    color = mag > 127 ? :dark : :light
    this = l.uri == e.uri # environment URI
    [{_: :tr, id: (l.R.fragment||l.uri), class: color, style: "background-color: #{this ? R.cs : ('#'+c*3)}",
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   {_: :a, href: (CGI.escapeHTML l.uri),
                    c: (CGI.escapeHTML (l[Title] || l[Label] ||l.R.basename).justArray[0])}
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     href = if t.uri == Directory
                              res = l.R
                              e.scheme + '://linkeddata.github.io/warp/#/list/' + e.scheme + '/' + res.host + res.path
                            else
                              l.uri
                            end
                     [{_: :a, href: CGI.escapeHTML(href), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon},
                      Containers[t.uri].do{|c| puts "typedcont"
                         n = c.R.fragment
                         {_: :a, href: l.uri+'?new', c: '+', title: "new #{n} in #{l.uri}"}
                      }]}
                 when LDP+'contains'
                   ViewA[Container][l,e,sort,direction]
                 when WikiText
                   Render[WikiText][l[k]]
                 else
                   l[k].justArray.map{|v|
                     case v
                     when Hash
                       v.R
                     else
                       v
                     end
                   }
                 end}, "\n"]
          }]}, "\n"]}

  ViewA[BasicResource] = -> r,e {
    uri = r.uri
    {class: :resource,
     c: [(if uri
          [({_: :a, href: uri, c: r[Date], class: :date} if r[Date]),
           ({_: :a, href: r.R.editLink(e), class: :edit, title: "edit #{uri}", c: R.pencil} if e.editable),
           {_: :a, href: uri, c: r[Title]||uri, class: :uri},'<br>']
          end),
         {_: :table, class: :html, id: id,
          c: r.map{|k,v|
            {_: :tr, property: k,
             c: case k
                when Type
                  types = v.justArray
                  {_: :td, class: :val, colspan: 2,
                   c: ['a ', types.intersperse(', ').map{|t|t.R.href}]}
                when Content
                  {_: :td, class: :val, colspan: 2, c: v}
                when WikiText
                  {_: :td, class: :val, colspan: 2, c: Render[WikiText][v]}
                else
                  [{_: :td, c: {_: :a, href: k, c: k.to_s.R.abbr}, class: :key},
                   {_: :td, c: v.justArray.map{|v|
                      case v
                      when Hash
                        v.R
                      else
                        v
                      end
                    }, class: :val}]
                end} unless k == 'uri'}}]}}

  ViewGroup[BasicResource] = -> g,e {
    [H.css('/css/html',true),
     g.resources(e).reverse.map{|r| # sort
       ViewA[BasicResource][r,e] }]}

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e { src = e.scheme+'://linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.css src + 'tabbedtab'),
     {_: :script, c: "
document.addEventListener('DOMContentLoaded', function(){
    var kb = tabulator.kb;
    var subject = kb.sym('#{e.scheme+':' + e.R.path.sub(/^\/tabulator/,'/')}');
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);"}, {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # add player and playlist resources
    graph['#snd'] = {'uri' => '#snd', Type => R[Container],
                  LDP+'contains' => g.values.map{|s| graph.delete s.uri # original resource
                    s.update({'uri' => '#'+URI.escape(s.R.path)})}} # localized playlist-entry
    graph['#audio'] = {Type => R[Sound+'Player']} # player
    graph[e.uri].do{|c|c.delete(LDP+'contains')}} # original container

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, {_: :a, id: :rand, href: '#rand', c: 'R'}, H.js('/js/audio'), {_: :style, c: "#snd {max-height: 24em; overflow:scroll}
#rand {color: #fff; background-color: brown; text-decoration: none; font-weight: bold; font-size: 3em; padding: .3em; border-radius: .1em}"}]}

end
