#watch __FILE__
class E

  def render mime,   graph, e
   E[Render+ mime].y graph, e
  end

  fn 'view/?',->d,e{
    F.keys.grep(/^view\/(?!application|text\/x-)/).map{|v|
      v = v[5..-1] # eat selector
      [{_: :a, href: e['REQUEST_PATH']+e.q.merge({'view'=>v}).qs, c: v},"<br>\n"]}}

  def response

    q = @r.q       # query-string
    g = q['graph'] # graph-function selector

    # empty response graph
    m = {}

    # identify graph
    graphID = (g && F['protograph/' + g] || F['protograph/'])[self,q,m]

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
          (g && F['graph/' + g] || F['graph/'])[self,q,m]
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
