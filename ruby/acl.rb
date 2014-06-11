#watch __FILE__
class R

  def aclURI
    if basename.index('.acl') == 0
      self
    elsif hierPart == '/'
      child '.acl'
    else
      dir.child '.acl.' + basename
    end
  end

  def allowAppend
    return true unless WAC
  end

  def allowRead
    return true unless WAC
  end

  def allowWrite
    return true unless WAC
  end

  WAC  = ENV['WAC']

end
