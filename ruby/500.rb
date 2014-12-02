class R

  E500 = -> x,e {
    error = {'uri' => e.uri,
             Title => [x.class, x.message].join(' '),
             Content => '<pre>' + x.backtrace.join("\n").noHTML + '<pre>'}
    graph = {e.uri => error}

    Stats[:status][500] ||= 0
    Stats[:status][500]  += 1
    Stats[:error][error]||= 0
    Stats[:error][error] += 1

    $stderr.puts [500, error[Title], x.backtrace]

    [500,{'Content-Type' => e.format},
     [Render[e.format].do{|p|p[graph,e]} ||
      graph.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]}

end
