# coding: utf-8
#watch __FILE__
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

    # convenience links to alternate container-filterings
    args = if e.q.has_key?('group') # unabbreviated-view
             {'bodies' => '', Label => '&darr;'}
           else                     # date-sort view
             {'group' => 'rdf:type', 'sort' => 'dc:date', 'reverse' => '', Label => '≡'}
           end
    label = args.delete Label
    viewURI = e.q.merge(args).qs
    graph[viewURI] = {'uri' => viewURI, Type => R[Container], Label => label}

    # pass 1. prune + analyze
    g.map{|u,p|
      recipients = p[To].justArray.map &:maybeURI

      # hide unless requested:
      graph.delete u unless bodies                                # unsummarized message
      p[DC+'source'].justArray.map{|s|graph.delete s.uri}         # provenance
      p[Creator].justArray.map(&:maybeURI).map{|a|graph.delete a} # author-description
      recipients.map{|a|graph.delete a}                           # recipient-description

      p[Title].do{|t|
        title = t[0].sub ReExpr, '' # strip prefix
        unless threads[title]
          p[Size] = 0               # member-count
          threads[title] = p        # thread
        end
        threads[title][Size] += 1}  # thread size

      recipients.map{|a|            # address weight
        weight[a] ||= 0
        weight[a] += 1}}

    # pass 2. cluster
    threads.map{|title,post|
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest wins
        container = a.R.dir.uri.t
        mid = URI.escape post[DC+'identifier'][0]

        # thread
        tags = []
        title = title.gsub(/\[[^\]]+\]/){|tag|tags.push tag[1..-2];nil}
        thread = {DC+'tag' => tags, 'uri' => '/thread/' + mid + '#' + URI.escape(post.uri), Date => post[Date], Title => title, Image => post[Image]}
        if post[Size] > 1 # thread
          thread.update({Size => post[Size],
                         Type => R[SIOC+'Thread']})
        else # singleton post
          thread[Type] = R[SIOC+'MailMessage']
          thread[Creator] = post[Creator]
        end

        # cluster container
        unless graph[container]
          clusters.push container
          graph[container] = {'uri' => container, Type => R[Container], LDP+'contains' => [], Label => a.R.fragment}
        end
        graph[container][LDP+'contains'].push thread }}

    clusters.map{|container| # child-count metadata
      graph[container][Size] = graph[container][LDP+'contains'].
                               justArray.inject(0){|sum,val| sum += (val[Size]||1)}}}

end
