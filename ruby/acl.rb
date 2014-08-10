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
    true
  end

  def allowWrite
#   false
    true
  end

end
