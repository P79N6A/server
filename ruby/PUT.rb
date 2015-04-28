watch __FILE__
class R

  def PUT
    return [400,{},[]] unless @r['CONTENT_TYPE']
    return [403,{},[]] unless allowWrite
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s # suffix from MIME
    return [406,{},[]] unless %w{gif html jpg json jsonld png n3 ttl}.member? ext

    # container for states
    versions = docroot.child '.v'

    # version URI
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 
    body = @r['rack.input'].read
    doc.w body unless body.empty?

    main = stripDoc.a('.' + ext) # canonical doc-URI

    main.delete if main.e # unlink prior
    doc.ln main           # link current

    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

  def MKCOL
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [405, {}, ["file exists"]] if file?
    return [405, {}, ["dir exists"]] if directory?
    mk
    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

  def writeResource re, build = true
    r = re.R # resource pointer
    ts = Time.now.iso8601.gsub /[-+:T]/, '' # timestamp slug
    path = fragmentPath          # version-base URI
    doc = path + '/' + ts + '.e' # version-doc URI
    s = if r.uri.match /#/  # relative subject-URI
          '#' + r.fragment # fragment
        elsif r.uri[-1] == '/'
          r.basename + '/' # container
        else
          r.path
        end
    re['uri'] = s     # identify resource
    graph = {s => re} # resource to graph
    doc.w graph, true # write graph
    cur = path.a '.e' # live-version URI
    cur.delete if cur.e # unlink old
    doc.ln_s cur      # link live-version
    buildDoc if build # update containing-doc
    puts "doc #{doc}"
    puts "current #{cur}"
  end

  def buildDoc
    resources = fragments
    doc = jsonDoc
    if !resources || resources.empty? # empty
      doc.delete                      # unlink
    else
      graph = {}
      resources.map{|f| f.nodeToGraph graph} # mash fragments
      doc.w graph, true                      # write doc
    end
  end

end
