#watch __FILE__
class R

  def aclURI
    if justPath == '/'
      '//' + @r['SERVER_NAME'] + '/.acl'
    elsif basename.index('.acl') == 0
      self
    else
      dirname + '/.acl.' + basename
    end
  end
=begin
COPY / STEAL

   // check if we are the domain owner
        if (is_file($this->_root_path.'.acl')) {
            $g = new Graph('', $this->_root_path.'.acl', '',$this->_root_uri.'.acl');
        
            if ($g->size() > 0) {
                // for the domain owner
                $this->_debug[] = "Graph size=".$g->size();

                $q = "PREFIX acl: <http://www.w3.org/ns/auth/acl#>
                      SELECT ?z WHERE { 
                        ?z acl:agent <".$this->_user."> .
                        }";
                $r = $g->SELECT($q);
                if (isset($r['results']['bindings']) && count($r['results']['bindings']) > 0) {
                    $this->_reason .= "User ".$this->_user." was authenticated as owner!";

                    return true;
                }
            }
        }
          
        // Recursively find a .acl
        $path = $this->_path;
        $uri = $this->_uri;
        $parent_path = (dirname($path) == $this->_root_path)?$path:dirname($path);
        $parent_uri = (dirname($uri) == $this->_root_uri)?$uri:dirname($uri);
        $break = false;

        // debug
        $this->_debug[] = " ";
        $this->_debug[] = "------------";
        $this->_debug[] = "Not the owner, going recursively! BASE=".$this->_path;
        $this->_debug[] = "User is: ".$this->_user;

        // walk path (force stop if we hit root level)
        while($path != dirname($this->_root_path)) {
            if ($break == true)
                return true;

            $r = $path;
            $this->_debug[] = "------------";
            $this->_debug[] = "Current level: ".$r;

            $resource = $uri;
            
            if ($r != $this->_root_path) {
                $acl_file = (substr(basename($r), 0, 4) != '.acl')?'/.acl.'.basename($r):'/'.basename($r);
                $acl_path = $parent_path.$acl_file;
                $acl_uri = (dirname($uri) == $this->_root_uri)?$acl_file:dirname($uri).$acl_file;
                $this->_debug[] = "Dir=".$r." | acl_path=".$acl_path." | acl_uri=".$acl_uri;
                $path = (dirname($path) == $this->_root_path)?$path:dirname($path).'/';
                $uri = (dirname($uri) == $this->_root_uri)?$uri:dirname($uri).'/';
                $this->_debug[] = 'Parent_path='.$path.' | parent_uri='.$uri;
            } else {
                $acl_path = $r.'.acl';
                $acl_uri = $uri.'.acl';
                $this->_debug[] = "ROOT Dir=".$r." | acl_path=".$acl_path." | acl_uri=".$acl_uri;
                if ($path == $this->_root_path)
                    $break = true;
            }

            if ($r == $this->_path) {
                $verb = 'accessTo';
            } else {
                $verb = 'defaultForNew';
                if (substr($resource, -1) != '/')
                    $resource = $resource.'/';
            }

            $this->_debug[] = "Verb=".$verb." | Resource=".$resource;
            
            if (is_file($acl_path)) { 
                $g = new Graph('', $acl_path, '',$acl_uri);
                if ($g->size() > 0) {
                    // specific authorization
                    $q = "PREFIX acl: <http://www.w3.org/ns/auth/acl#>".
                         "SELECT * WHERE { ".
                            "?z acl:agent <".$this->_user."> ; ".
                            "acl:mode acl:".$method." ; ". 
                            "acl:".$verb." <".$resource."> . ". 
                            "}";
                            
                    $this->_debug[] = $q;
                    $res = $g->SELECT($q);
                    if (isset($res['results']['bindings']) && count($res['results']['bindings']) > 0) {
                        $this->_reason .= 'User '.$this->_user.' is allowed ('.$method.') access to '.$r."\n";
                        return true;
                    }                   
                    
                    // public authorization
                    $q = "PREFIX acl: <http://www.w3.org/ns/auth/acl#>".
                         "SELECT * WHERE { ".
                            "?z acl:agentClass <http://xmlns.com/foaf/0.1/Agent>; ".
                            "acl:mode acl:".$method."; ".
                            "acl:".$verb." <".$resource."> . ".
                            "}";
                    $this->_debug[] = $q;
                    $res = $g->SELECT($q);
                    if (isset($res['results']['bindings']) && count($res['results']['bindings']) > 0) {
                        $this->_reason .= 'Everyone is allowed ('.$method.') '.$verb.' to '.$r."\n";
                        return true;
                    } 
                    
                    $this->_reason = 'No one is allowed ('.$verb.') '.$method.' for resource '.$this->_uri."\n";
             
                    return false;
                }

=end

  def can
    true
  end

end
