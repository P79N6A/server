class E

  Render = 'render/'

  def render mime,   graph, e
   E[Render+ mime].y graph, e
  end

  def response

    q = @r.q       # query-string
    g = q['graph'] # graph-function selector

    # empty response graph
    m = {}

    # identify graph
    graphID = (F['protograph/' + g] || F['protograph/'])[self,q,m]

    return F[E404][self,@r] if m.empty?

    # identify response
    @r['ETag'] ||= [graphID, q, @r.format, Watch].h

    maybeSend @r.format, ->{
      
      # response
      r = E'/E/req/' + @r['ETag'].dive
      if r.e # response exists
        r    # cached response
      else
        
        # graph
        c = E '/E/graph/' + graphID.dive
        if c.e # graph exists
          m.merge! c.r true
        else
          # construct graph
          (F['graph/' + g] || F['graph/'])[self,q,m]
          # cache graph
          c.w m,true
        end

        # graph sort/filter
        E.filter q, m, self

        # cache response
        r.w render @r.format, m, @r
      end }
  end

end
