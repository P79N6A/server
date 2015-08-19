# coding: utf-8
watch __FILE__
class R

  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    graph.delete e.uri
    bodies = e.q.has_key? 'bodies'
    e.q['sort'] ||= Size
    e.q['reverse'] ||= 'reverse'
    group = (e.q['group']||To).expand
    size = g.keys.size
    threads = {}
    clusters = []
    weight = {}
#    graph[e.uri] = {'uri' => e.uri, Label => e.R.path, Type => R[Container]}

    # link to alternate container-filterings
    args = if e.q.has_key?('group') # unabbreviated-view
             {'bodies' => '', Label => '&darr;'}
           else                     # date-sort view
             {'group' => 'rdf:type', 'sort' => 'dc:date', 'reverse' => '', Label => '≡'}
           end
    label = args.delete Label
    viewURI = e.q.merge(args).qs
    graph[viewURI] = {'uri' => viewURI, Type => R[Container], Label => label}

    g.map{|u,p| # analysis pass

      # hide unless requested:
      graph.delete u unless bodies # full-message
      p[DC+'source'].justArray.map{|s| # provenance
        graph.delete s.uri}

      p[Title].do{|t| # title
        title = t[0].sub ReExpr, '' # strip reply-prefix
        unless threads[title] # init thread
          p[Size] = 0         # member-count
          threads[title] = p  # thread data
        end
        p[DC+'image'].do{|i|
          threads[title][LDP+'contains'] ||= []
          threads[title][LDP+'contains'].concat i
        }
        threads[title][Size] += 1 # count occurrence
      }
      p[Creator].justArray.map(&:maybeURI).map{|a|
        graph.delete a } # hide author-description
      p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1   # count recipient-occurrence
        graph.delete a}} # hide recipient-description

    threads.map{|title,post| # cluster pass
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest wins
        container = a.R.dir.uri.t
        mid = URI.escape post[DC+'identifier'][0]
        thread = {'uri' => '/thread/' + mid + '#' + URI.escape(post.uri), Date => post[Date], Title => title}
        if post[Size] > 1
          thread.update({Size => post[Size],
                         Type => R[SIOC+'Thread']})
        else
          thread[Type] = R[SIOC+'MailMessage']
          thread[Creator] = post[Creator]
        end
        post[Image].do{|i| thread[Image] = i }

        unless graph[container]
          clusters.push container
          graph[container] = {'uri' => container, Type => R[Container], LDP+'contains' => [], Label => a.R.fragment}
        end
        graph[container][LDP+'contains'].push thread }}

    clusters.map{|container| # child-count metadata
      graph[container][Size] = graph[container][LDP+'contains'].
                               justArray.inject(0){|sum,val| sum += (val[Size]||1)}}}

end
