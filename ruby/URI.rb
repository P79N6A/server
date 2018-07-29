class RDF::Node
  def R; WebResource.new to_s end
end
class RDF::URI
  def R; WebResource.new to_s end
end
class String
  def R; WebResource.new self end
end
class Symbol
  def R; WebResource.new to_s end
end

class WebResource < RDF::URI
  # constructor
  def self.[] u; WebResource.new u end
  # cast to WebResource
  def R; self end

  PWD = Pathname.new File.expand_path '.'

  module URIs
    #URI constants
    W3 = 'http://www.w3.org/'
    OA = 'https://www.w3.org/ns/oa#'
    Purl = 'http://purl.org/'
    DC   = Purl + 'dc/terms/'
    DCe  = Purl + 'dc/elements/1.1/'
    SIOC = 'http://rdfs.org/sioc/ns#'
    Link = DC + 'link'
    Schema = 'http://schema.org/'
    Media = 'http://search.yahoo.com/mrss/'
    Podcast = 'http://www.itunes.com/dtds/podcast-1.0.dtd#'
    Comments = 'http://wellformedweb.org/CommentAPI/commentRss'
    Sound    = Purl + 'ontology/mo/Sound'
    Image    = DC + 'Image'
    Video    = DC + 'Video'
    RSS      = Purl + 'rss/1.0/'
    Cache    = DC   + 'cache'
    Date     = DC   + 'date'
    Title    = DC   + 'title'
    Abstract = DC   + 'abstract'
    Identifier = DC + 'identifier'
    Post     = SIOC + 'Post'
    To       = SIOC + 'addressed_to'
    From     = SIOC + 'has_creator'
    Creator  = SIOC + 'has_creator'
    Content  = SIOC + 'content'
    BlogPost = SIOC + 'BlogPost'
    Email    = SIOC + 'MailMessage'
    InstantMessage = SIOC + 'InstantMessage'
    Resource = W3   + '2000/01/rdf-schema#Resource'
    Stat     = W3   + 'ns/posix/stat#'
    Atom     = W3   + '2005/Atom#'
    Type     = W3 + '1999/02/22-rdf-syntax-ns#type'
    Label    = W3 + '2000/01/rdf-schema#label'
    Size     = Stat + 'size'
    Mtime    = Stat + 'mtime'
    Container = W3  + 'ns/ldp#Container'
    Contains  = W3  + 'ns/ldp#contains'

    def + u; R[to_s + u.to_s] end
    def match p; to_s.match p end
  end
  include URIs

  module HTTP
    # host-mapped handler lambdas
    Host = {}

    # original URL on file at third-party - network lookup
    Short = -> re {
      host = re.env['HTTP_HOST']
      scheme = 'http' + (InsecureShorteners.member?(host) ? '' : 's') + '://'
      source = scheme + host + re.path
      dest = nil
      cache = R['/.cache/' + host + (re.path[0..2] || '') + '/' + (re.path[3..-1] || '') + '.u']
      if cache.exist?
        dest = cache.readFile
      else
        dest = (Net::HTTP.get_response (URI.parse source))['location']
        cache.writeFile dest
        puts "#{re.path[1..-1]} -> #{dest}"
      end
      [200, {'Content-Type' => 'text/html'},
       [re.htmlDocument({source => {'dest' => dest ? dest.R : nil}})]]}

    InsecureShorteners = %w{bos.gl w.bos.gl}
    %w{t.co bit.ly buff.ly bos.gl w.bos.gl dlvr.it ift.tt cfl.re nyti.ms trib.al ow.ly n.pr a.co youtu.be}.map{|host|
      Host[host] = Short}

    # URI encoded in another URI - no network lookup
    Unwrap = -> key {
      -> re {
        location = re.q[key.to_s.downcase]
        location ? [302,{'Location' => location},[]] : [404,{},[]]}}

    Host['exit.sc']             = Unwrap[:url]
    Host['lookup.t-mobile.com'] = Unwrap[:origURL]
    Host['l.instagram.com']     = Host['images.duckduckgo.com'] = Host['proxy.duckduckgo.com'] = Unwrap[:u]
    Host['youtu.be'] = -> re {[302,{'Location' => 'https://www.youtube.com/watch?v=' + re.path[1..-1]},[]]}

  end
  module HTML
    BlankLabel = %w{com comments r status reddit twitter www}
    BoldLabel = %w{boston collapse providence}
  end
  module Webize

    def triplrUriList addHost = false
      base = stripDoc
      name = base.basename

      # containing file
      yield base.uri, Type, R[Container]
      yield base.uri, Title, name
      prefix = addHost ? "https://#{name}/" : ''

      lines.map{|line|
        t = line.chomp.split ' '
        unless t.empty?
          # URI
          uri = prefix + t[0]
          title = t[1..-1].join ' ' if t.size > 1
          yield base.uri, Contains, uri.R
          yield uri, Type, R[Resource]
          yield uri, Title, title if title
        end}
    end
  end
  alias_method :uri, :to_s
end
