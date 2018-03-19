class RDF::Node
  def R; WebResource.new to_s end
end
class RDF::URI
  def R; WebResource.new to_s end
end
class String
  def R; WebResource.new self end
end
class WebResource < RDF::URI
  def R; self end
  def self.[] u; WebResource.new u end
  alias_method :uri, :to_s
  module URIs
    def + u; R[to_s + u.to_s] end
    def match p; to_s.match p end

    # short names for URIs
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
    Resource = W3   + '2000/01/rdf-schema#Resource'
    Stat     = W3   + 'ns/posix/stat#'
    Atom     = W3   + '2005/Atom#'
    Type     = W3 + '1999/02/22-rdf-syntax-ns#type'
    Label    = W3 + '2000/01/rdf-schema#label'
    Size     = Stat + 'size'
    Mtime    = Stat + 'mtime'
    Container = W3  + 'ns/ldp#Container'
    Contains  = W3  + 'ns/ldp#contains'

    #TODO dynamic list from .conf/proxyhosts
    MITMhosts = %w{i-ne.ws l.instagram.com t.co tinyurl.com}

  end
  module Webize

    def triplrUriList addHost = false
      base = stripDoc
      name = base.basename

      # list resource
      yield base.uri, Type, R[DC+'List']
      yield base.uri, Title, name
      prefix = addHost ? "https://#{name}/" : ''

      # lines
      (open localPath).readlines.map{|line|
        t = line.chomp.split ' '
        unless t.empty?
          uri = prefix + t[0]
          title = t[1..-1].join ' ' if t.size > 1

          # triples
          yield uri, Type, R[Resource]
          if title
            yield uri, Title, title
          end
        end}
    end
  end

end
