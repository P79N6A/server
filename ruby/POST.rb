watch __FILE__
class R

  def POST

    # bespoke POST handler for path
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    return [403,{},[]] if !allowWrite

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    else
      putDoc
    end

  end

  def formPOST
    form = Rack::Request.new(@r).params
    return [400,{},['fragment-argument required']] unless form['fragment']

    fragment = form['fragment'].slugify
    subject = s = uri + '#' + fragment
    graph = {s => {'uri' => s}}

    # form data to graph
    form.keys.-(['fragment']).map{|p|
      o = form[p]
      o = if o.match HTTP_URI
            o.R
          elsif p == Content
            StripHTML[o]
          else
            o
          end
      graph[s][p] ||= []
      graph[s][p].push o unless o.class==String && o.empty?}

    # store graph
    s.R.a('.e').w graph, true

    [303,{'Location'=>uri+'?edit'},[]]
  end

end
