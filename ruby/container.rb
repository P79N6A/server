# coding: utf-8
#watch __FILE__
class R

  def triplrContainer
    dir = uri.t
    yield dir, Type, R[Container]
    yield dir, SIOC+'has_container', parentURI unless path=='/'
    yield dir, Date, mtime.iso8601
    contained = c
    yield dir, Size, contained.size
    if contained.size < 22 # provide some "lookahead" on container children if small - GET URI for full
      contained.map{|c|
        if c.directory?
          child = c.descend # trailing-slash convention
          yield dir, LDP+'contains', child
#          yield child.uri, Type, R[Container]
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
    order = e.q.has_key?('reverse') ? :reverse : :id
    ["\n",
     H.css('/css/table'), "\n",
     H.css('/css/icons'), "\n",
     H.css('/css/container'), "\n",
     {_: :table, :class => :tab,
      c: [{_: :tr,
           c: keys.map{|k|
             this = sort == k
             q = e.q.merge({'sort' => k.shorten})
             if order == :reverse
               q.delete 'reverse'
             else
               q['reverse'] = ''
             end
             [{_: :th, property: k, class: this ? :this : :that,
               c: {_: :a, rel: :nofollow, href: q.qs, c: k.R.abbr}}, "\n"]}}, "\n",
          g.resources(e).send(order).map{|row|
            TableRow[row,e,sort,keys]}]}, "\n"]}

  ViewA[Container] = -> r, e {
    re = r.R
    uri = re.uri
    e[:seen] ||= {}
    unless e[:seen][uri]
      e[:seen][uri] = true
      path = (re.path||'').t
      group = e.q['group']
      sort = (e.q['sort']||'uri').expand
      {class: :container, id: re.fragment,
       c: r[LDP+'contains'].do{|c|
         sizes = c.map{|r|r[Size] if r.class == Hash}.flatten.compact
         maxSize = sizes.max
         sized = !sizes.empty? && maxSize > 1
         width = maxSize.to_s.size
         c.sortRDF(e).send((sized||sort==Date) ? :reverse : :id).map{|r|
           data = r.class == Hash
           [{_: :a, href: r.R.uri, class: :member,
             c: [(if data && sized && r[Size]
                  s = r[Size].justArray[0]
                  [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                  end),
                 ([r[Date].justArray[0].to_s,' '] if data && sort==Date),
                 data && (r[Title] || r[Label]) || r.R.abbr[0..64]
                ]}, data ? "<br>" : " "]}}}
    end}

  Icons = {
    Container => :dir,
    Directory => :dir,
    FOAF+'Person' => :person,
    GraphDoc => :graph,
    Image => :img,
    SIOC+'Thread' => :thread,
    SIOC+'Usergroup' => :group,
    Stat+'File' => :file,
    '#editable' => :scissors,
  }

  TableRow = -> l,e,sort,keys {
    [{_: :tr, about: l.uri,
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   l.R.do{|r|
                     {_: :a, href: r.uri, c: l[Title]||l[Label]||r.basename}}
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     {_: :a, href: l.uri, c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when LDP+'contains'
                   ViewA[Container][l,e]
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
