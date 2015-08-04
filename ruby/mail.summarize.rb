# coding: utf-8
class R

  # summarize a set of emails to overview-containers
  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    graph.delete e.uri
    bodies = e.q.has_key? 'bodies'
    rdf = e.format != 'text/html'
    e.q['sort'] ||= Size
    e.q['reverse'] ||= 'reverse'
    group = (e.q['group']||To).expand
    size = g.keys.size
    threads = {}
    clusters = []
    weight = {}

    # base container
    graph[e.uri] = {
      'uri' => e.uri, Label => e.R.basename,
      Type => R[Container],
      SIOC+'has_container' => e.R.parentURI,
    }

    # link to alternate container-filterings - date-order and expanded-content view
    unless rdf
      args = if e.q.has_key?('group') # unabbreviated-view
               {'bodies' => '', Label => '&darr;'}
             else                     # date-sort view
               {'group' => 'rdf:type', 'sort' => 'dc:date', 'reverse' => '', Label => '≡'}
             end
      label = args.delete Label
      viewURI = e.q.merge(args).qs
      graph[viewURI] = {'uri' => viewURI, Type => R[Container], Label => label}
    end

    g.map{|u,p| # statistics + prune pass
      graph.delete u unless bodies # hide full-message
      p[DC+'source'].justArray.map{|s| # hide originating-file metadata
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
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest address wins
        container = a.R.dir.uri.t # container URI
        id = URI.escape post[DC+'identifier'][0]
        item = {'uri' => '/thread/' + id + '#' + URI.escape(post.uri),
                Date => post[Date],
                Title => title,
                Size => post[Size],
                Type => R[SIOC+'Thread']} # thread resource
        post[DC+'image'].do{|i| item[LDP+'contains'] = i }

        unless graph[container] # cluster-container
          clusters.push container
          graph[container] = {'uri' => container, Type => R[Container], LDP+'contains' => [], Label => a.R.fragment}
        end
        graph[item.uri] ||= item if rdf # thread to RDF-graph
        graph[container][LDP+'contains'].push item }} # container -> thread link

    clusters.map{|container| # count cluster-sizes
      graph[container][Size] = graph[container][LDP+'contains'].
                               justArray.inject(0){|sum,val| sum += (val[Size]||0)}}}

end
