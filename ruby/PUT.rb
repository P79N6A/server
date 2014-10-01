#watch __FILE__

class R

  def MKCOL
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [405, {}, ["file exists"]] if file?
    return [405, {}, ["dir exists"]] if directory?
    mk
    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

  def PUT
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [403,{},[]] if !allowWrite
    return [406,{},[]] unless %w{gif html jpg json jsonld png n3 ttl}.member? ext

    # container for states
    versions = docroot.child '.v'

    # identifier for current version
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 

    # store version
    doc.w @r['rack.input'].read

    main = stripDoc.a('.' + ext) # always the current doc

    main.delete if main.e # unlink prior
    doc.ln_s main         # link current

    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

  def putForm
    form = Rack::Request.new(@r).params
    frag = form['fragment']
    return [400,{},['fragment-argument required']] unless frag
    frag = form[Title] if frag.empty? && form[Title]
    frag = frag.slugify

    subject = s = uri + '#' + frag
    r = s.R
    graph = {s => {'uri' => s}}
    main = r.docroot.a '.' + r.fragment + '.e'

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
    ts = Time.now.iso8601.sub('-','.').sub('-','/').gsub /[+:T]/, ''
    doc = r.fragmentPath + '/' + ts + '.e'
    doc.w graph, true
    main.delete if main.e
    doc.ln_s main

    [303,{'Location'=>uri+'?edit'},[]]
  end

end
