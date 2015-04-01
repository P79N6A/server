# coding: utf-8
#watch __FILE__
class R

  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
    yield dir, Type, R[Directory]
    yield dir, SIOC+'has_container', parentURI unless path=='/'
    mt = mtime
    yield dir, Date, mt.iso8601
    yield dir, Mtime, mt.to_i
    contained = c
    yield dir, Size, contained.size
    if contained.size < 22 # provide some "lookahead" on container children if small - GET URI for full
      contained.map{|c|
        if c.directory?
          child = c.descend # trailing-slash convention
          yield dir, LDP+'contains', child
        else
          yield dir, LDP+'contains', c.stripDoc
        end
      }
    end
  end

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
               c: {_: :a, rel: :nofollow, href: CGI.escapeHTML(q.qs), c: k.R.abbr}}, "\n"]}}, "\n",
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
               data && CGI.escapeHTML((r[Title] || r[Label] || r.R.fragment || r.R.basename).justArray[0]) || r.R.abbr[0..64]
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
#  types.map{|t| R::Containers[t.uri].do{|c|
#              n = c.R.fragment
#              [' ', {_: :a, href: id+'?new', class: :new, c: ['+',n], title: "post a #{n} to #{id.R.basename}"}]}}

  TableRow = -> l,e,sort,direction,keys {
    mag = l[Size].justArray[0].do{|s|s * e[:scale]} || 0
    c = '%02x' % (255 - mag)
    color = mag > 127 ? :white : :black
    [{_: :tr, id: (l.R.fragment||l.uri), class: color, style: "color:#{color};background-color: ##{c*3}",
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   l.R.do{|r|
                     {_: :a, href: CGI.escapeHTML(r.uri), c: CGI.escapeHTML((l[Title]||l[Label]||r.basename).justArray[0])}}
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     href = if t.uri == Directory
                              res = l.R
                              e.scheme + '://linkeddata.github.io/warp/#/list/' + e.scheme + '/' + res.host + res.path
                            else
                              l.uri
                            end
                     {_: :a, href: CGI.escapeHTML(href), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when LDP+'contains'
                   ViewA[Container][l,e,sort,direction]
                 when WikiText
                   Render[WikiText][l[k]]
                 else
                   l[k].html
                 end}, "\n"]
          }]}, "\n"]}

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e {
    src = e.scheme + '://linkeddata.github.io/tabulator/'
    uri = e.scheme + ':' + e.R.path.sub(/^\/tabulator/,'/')
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.css src + 'tabbedtab'),
     {_: :script, c: "
document.addEventListener('DOMContentLoaded', function(){
    var kb = tabulator.kb;
    var subject = kb.sym('#{uri}');
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);
"},
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

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
