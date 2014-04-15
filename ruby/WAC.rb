watch __FILE__
class R

  def aclURI
    if pathSegment == '/'
      'http://' + @r['SERVER_NAME'] + '/.acl'
    elsif basename.index('.acl') == 0
      self
    else
      dirname + '/.acl.' + basename
    end
  end

end
