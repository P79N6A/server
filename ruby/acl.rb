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
    return allowWrite
  end

  def allowRead
    return true
  end

  def allowWrite
    return false 
  end

end
