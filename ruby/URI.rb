class RDF::Node
  def R; WebResource.new to_s end
end
class RDF::URI
  def R; WebResource.new to_s end
end
class String
  def R; WebResource.new self end
end

# parametric DNS-resolver
Resolv::DefaultResolver.replace_resolvers([Resolv::DNS.new(:nameserver => ENV['NAMESERVER'] || '8.8.8.8')])

class WebResource < RDF::URI

  def R; self end # casting method - already a WebResource
  def self.[] u; WebResource.new u end # enable R[] constructor syntax

  alias_method :uri, :to_s
  PWD = Pathname.new File.expand_path '.'

  module URIs
    def + u; R[to_s + u.to_s] end
    def match p; to_s.match p end

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
    Date     = DC   + 'date'
    Title    = DC   + 'title'
    Abstract = DC   + 'abstract'
    Post     = SIOC + 'Post'
    To       = SIOC + 'addressed_to'
    From     = SIOC + 'has_creator'
    Creator  = SIOC + 'has_creator'
    Content  = SIOC + 'content'
    BlogPost = SIOC + 'BlogPost'
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

  end
  module HTTP

    ## short-URI resolution, cached with no expiry (do any major services allow editing?)
    Short = -> re {
      host = re.env['HTTP_HOST']
      source = re.env['rack.url_scheme'] + '://' + host + re.path
      dest = nil

      cache = R['/.cache/' + host + (re.path[0..2] || '') + '/' + (re.path[3..-1] || '') + '.u']
      if cache.exist?
        dest = cache.readFile
      else
        dest = (Net::HTTP.get_response (URI.parse source))['location']
        cache.writeFile dest
        puts "#{re.path[1..-1]} -> #{dest}"
      end

      [200, {'Content-Type' => 'text/html'}, [re.htmlDocument({source => {'dest' => dest ? dest.R : nil}})]]}

  end
  module Webize

    def triplrUriList addHost = false
      base = stripDoc
      name = base.basename

      # URI-list file
      yield base.uri, Type, R[DC+'List']
      yield base.uri, Title, name
      prefix = addHost ? "https://#{name}/" : ''

      # URIs
      lines.map{|line|
        t = line.chomp.split ' '
        unless t.empty?
          uri = prefix + t[0]
          title = t[1..-1].join ' ' if t.size > 1
          yield uri, Type, R[Resource]
          yield uri, Title, title if title
        end}
    end
  end

end
