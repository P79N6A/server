# coding: utf-8
#watch __FILE__
class R

  Identify[SIOC+'Thread'] = -> thread, forum, env {
    forum.uri + Time.now.iso8601[0..10].gsub(/[-T]/,'/') + thread[Title].slugify + '/'
  }

  Identify[SIOC+'BoardPost'] = -> post, thread, env {
    uri = thread.uri + Time.now.iso8601.gsub(/[-+:T]/, '')
    post[SIOC+'reply_to'] = R[thread.uri + '?new&reply_of=' + CGI.escape(uri)]
    uri
  }

  Create[SIOC+'Thread'] = -> thread, forum, env {
    thread[SIOC+'has_container'] = R[forum.uri]
  }

  Create[SIOC+'BoardPost'] = -> post, thread, env {
    env.q['reply_of'].do{|re|
      post[SIOC+'has_parent'] = re.R
    }
    post[SIOC+'has_discussion'] = R[thread.uri]
    post[Title] = thread[Title]
  }

  MessagePath = -> id{ # rfc2822 Message-ID -> /path
    msg, domainname = id.downcase.sub(/^</,'').sub(/>.*/,'').gsub(/[^a-zA-Z0-9\.\-@]/,'').split '@'
    dname = (domainname||'').split('.').reverse
    case dname.size
    when 0
      dname.unshift 'none','nohost'
    when 1
      dname.unshift 'none'
    end
    tld = dname[0]
    domain = dname[1]
    ['', 'address', tld, domain[0], domain, *dname[2..-1], '@', id.h[0..1], msg].join('/')}

  AddrPath = ->address{ # email-address -> /path
    address = address.downcase
    person, domainname = address.split '@'
    dname = (domainname||'').split('.').reverse
    tld = dname[0]
    domain = dname[1] || 'localdomain'
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}

  GET['/address'] = -> e,r {e.justPath.response} # free hostname

  GET['/thread'] = -> e,r { # reconstruct thread
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of','sioc:reply_of', m # recursive walk
    return E404[e,r] if m.empty?                                       # nothing found?

    # thread identity
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'

    e.condResponse ->{ r[:thread] = true
      # add thread title to document
      m.values.find{|r|
        r.class == Hash && r[Title]}.do{|t|
        title = t.justArray[0]
        r[:title] = title.sub ReExpr, '' if title.class==String}
      # render RDF or HTML
      Render[r.format].do{|p|p[m,r]} ||
        m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)
    }}

end
