# coding: utf-8
#watch __FILE__
class R

  def triplrContainer
    dir = uri.t # trailing-slash

    yield dir, Type, R[Container]
    yield dir, Type, R[Directory]
    yield dir, SIOC+'has_container', parentURI unless path=='/'
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601

    # direct children
    contained = c
    yield dir, Size, contained.size
    if contained.size < 22 # provide some "lookahead" on small contained-containers. GET them directly for full (or paged, summarized) contents
      contained.map{|c|
        if c.directory?
          child = c.descend # trailing-slash convention on containers
          yield dir, LDP+'contains', child
        else # doc
          yield dir, LDP+'contains', c.stripDoc # link to generic resource
        end
      }
    end

  end

  # POSTable container -> contained types
  Containers = {
    Wiki => SIOC+'WikiArticle',
    Forum            => SIOC+'Thread',
    SIOC+'Thread'    => SIOC+'BoardPost',
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

  ViewA[Container] = -> r, e, sort, direction { # view a container as HTML
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
         uri = r.R.uri
         data = r.class == Hash
         [{_: :a, href: uri, class: :member, selectable: true, id: uri,
           c: [(if data && sized && r[Size]
                s = r[Size].justArray[0]
                [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                end),
               (if data && sort==Date
                [r[Date].justArray[0].to_s,' ']
                end),
               (if data
                CGI.escapeHTML((r[Title] || r[Label] || r.R.fragment || r.R.basename).justArray[0].to_s)
               else
                 uri
                end)
              ]}, "<br>",
          (if data && (c = r[LDP+'contains'])
           [c.map{|i|{_: :a, href: r.uri, c: {_: :img, src: i.uri, style: 'max-width: 360px; max-height: 360px'}}},'<br>']
           end)
         ]}}}}

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # create player and playlist resources
    graph['#snd'] = {'uri' => '#snd', Type => R[Container],
                  LDP+'contains' => g.values.map{|s| graph.delete s.uri # original entry
                    s.update({'uri' => '#'+URI.escape(s.R.path)})}} # localized playlist-entry
    graph['#audio'] = {Type => R[Sound+'Player']} # player
    graph[e.uri].do{|c|c.delete(LDP+'contains')}} # original container

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, {_: :a, id: :rand, href: '#rand', c: 'R'}, H.js('/js/audio'), {_: :style, c: "#snd {max-height: 24em; overflow:scroll}
#rand {color: #fff; background-color: brown; text-decoration: none; font-weight: bold; font-size: 3em; padding: .3em; border-radius: .1em}"}]}
  def triplrImage &f
    yield uri, Type, R[Image]
  end

  GET['/thumbnail'] = -> e,r {
    path = e.path.sub /^.thumbnail/, ''
    path = '//' + r.host + path unless path.match /^.domain/
    i = R path
    if i.file? && i.size > 0
      if i.ext.match /SVG/i
        path = i
      else
        stat = i.node.stat
        path = R['/cache/thumbnail/' + (R.dive [stat.ino,stat.mtime].h) + '.png']
        if !path.e
          path.dir.mk
          if i.mime.match(/^video/)
            `ffmpegthumbnailer -s 360 -i #{i.sh} -o #{path.sh}`
          else
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "360x360" #{path.sh}`
          end
        end
      end
      path.e ? path.setEnv(r).fileGET : E404[e,r]
    else
      E404[e,r]
    end}

  ViewA[Image] = ->img,e{
    image = img.R
    {_: :a, href: image.uri,
     c: {_: :img, class: :thumb,
         src: if image.ext.downcase == 'gif'
                image.uri
              else
                '/thumbnail' + image.path
              end}}}

  ViewGroup[Image] = -> g,e {
    [{_: :style, c: "img.thumb {max-width: 360px; max-height: 360px}"},
     g.map{|u,r| ViewA[Image][r,e]}]}

end
