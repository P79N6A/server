#watch __FILE__
class R

  def [] p; predicate p end
  def []= p,o
    if o
      setFs p,o
    else
      (predicate p).map{|o|
        unsetFs p,o}
    end
  end

  def predicatePath p, s = true
    container.as s ? p.R.shorten : p
  end

  def objectPath o
    p,v = (if o.respond_to? :uri
             [R[o.uri].path, nil]
           else
             literal o
           end)
    [(a p), v]
  end

  def literal o
    str = nil
    ext = nil
    if o.class == String
      str = o;         ext='.txt'
    else
      str = o.to_json; ext='.json'
    end
    ['/'+str.h+ext, str]
  end

  def predicates
    container.c.map{|c|c.base.expand.R}
  end

  def predicate p, short = true
    p = predicatePath p, short
    p.node.take.map{|n|
      if n.file? # literal
        o = n.R
        case o.ext
        when "json"
          o.r true
        else
          o.r
        end
      else # resource
       R[n.to_s.unpath p.d.size]
      end}
  end

  def setFs p, o, undo = false, short = true
    p = predicatePath p, short # s+p URI
    t,literal = p.objectPath o # s+p+o URI
    if o.class == R # resource
      if undo
        t.delete if t.e # undo
      else
        unless t.e
          if o.f    # file?
            o.ln t  # link
          else
            t.mk    # dirent
          end
        end
      end
    else # literal
      if undo
        t.delete if t.e  # remove 
      else
        t.w literal unless t.e # write
      end
    end
  end

  def unsetFs p,o
    setFs p,o,true
  end

  def index p,o
    return unless o.class == R
    p.R.indexPath.setFs o,self,false,false
  end

  # reachable graph along named predicate
  def walk p, g={}, v={}
    graph g       # (accumulative) graph
    v[uri] = true # visited-mark
    rel = g[uri].do{|s|s[p]} ||[]
    rev = (p.R.po self) ||[]
    rel.concat(rev).map{|r|
      v[r.uri] || (r.R.walk p,g,v)}
    g
  end

  def po o
    indexPath.predicate o, false
  end

  def indexPath
    R['/index/'+shorten.uri]
  end

  def triplrDoc &f
    stripDoc.glob('#*').map{|s|
      s.triplrResource &f}
  end

  def triplrResource
    predicates.map{|p|
      self[p].map{|o| yield uri, p.uri, o}}
  end

  GET['/cache'] = E404
  GET['/index'] = E404

end
