watch __FILE__
class R

  def POST

    # custom POST handler on URI
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    return [403,{},[]] if !allowWrite
    puts "POST #{uri} #{@r['CONTENT_TYPE']}"

    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      formPOST
    else
      putDoc
    end
  end

  def formPOST
    form = Rack::Request.new(@r).params
    section = form['section']
    return [400,{},[]] unless section
    s = uri + '#' + section.gsub(/\W+/,'_')
    graph = {'uri' => s}

    form.keys.-(['section']).map{|p|
      o = form[p]
      o = if o.match HTTP_URI
            o.R
          elsif p == Content
            StripHTML[o]
          else
            o
          end
      graph[p] ||= []
      graph[p].push o unless o.class==String && o.empty?
    }

    puts graph
    [303,{'Location'=>uri+'?edit'},[]]
  end

end
