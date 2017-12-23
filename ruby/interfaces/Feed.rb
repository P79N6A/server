# coding: utf-8
class WebResource
  module Feed
    include URIs

    def feeds; puts (nokogiri.css 'link[rel=alternate]').map{|u|join u.attr :href} end

    def fetchFeed
      head = {} # request header
      cache = R['/.cache/'+uri.sha2+'/'] # storage
      etag = cache + 'etag'      # cache etag URI
      priorEtag = nil            # cache etag value
      mtime = cache + 'mtime'    # cache mtime URI
      priorMtime = nil           # cache mtime value
      body = cache + 'body.atom' # cache body URI
      if etag.e
        priorEtag = etag.readFile
        head["If-None-Match"] = priorEtag unless priorEtag.empty?
      elsif mtime.e
        priorMtime = mtime.readFile.to_time
        head["If-Modified-Since"] = priorMtime.httpdate
      end
      begin # conditional GET
        open(uri, head) do |response|
          curEtag = response.meta['etag']
          curMtime = response.last_modified || Time.now rescue Time.now
          etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # new ETag value
          mtime.writeFile curMtime.iso8601 if curMtime != priorMtime # new Last-Modified value
          resp = response.read
          unless body.e && body.readFile == resp
            body.writeFile resp # new cached body
            ('file:'+body.localPath).R.indexFeed :format => :feed, :base_uri => uri # run indexer
          end
        end
      rescue OpenURI::HTTPError => error
        msg = error.message
        puts [uri,msg].join("\t") unless msg.match(/304/)
      end
    rescue Exception => e
      puts uri, e.class, e.message
    end
    def fetchFeeds; open(localPath).readlines.map(&:chomp).map(&:R).map(&:fetchFeed) end

    alias_method :getFeed, :fetchFeed

    def indexFeed options = {}
      g = RDF::Repository.load self, options
      g.each_graph.map{|graph|
        graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
          time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
          doc =  R["/#{time}#{slug}.ttl"]
          unless doc.e
            doc.dir.mkdir
            cacheBase = doc.stripDoc
            graph << RDF::Statement.new(graph.name, R[DC+'cache'], cacheBase)
            RDF::Writer.open(doc.localPath){|f|f << graph}
            puts cacheBase
          end
          true}}
      self
    rescue Exception => e
      puts uri, e.class, e.message
    end

    class Format < RDF::Format
      content_type     'application/atom+xml', :extension => :feed
      content_encoding 'utf-8'
      reader { WebResource::Feed::Reader }
    end

    class Reader < RDF::Reader
      include URIs
      format Format

      def initialize(input = $stdin, options = {}, &block)
        @doc = (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read.to_utf8
        @base = options[:base_uri]
        if block_given?
          case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
          end
        end
        nil
      end

      def each_triple &block; each_statement{|s| block.call *s.to_triple} end

      def each_statement &fn # triples flow (left ← right)
        resolveURIs(:normalizeDates, :normalizePredicates,:rawTriples){|s,p,o|
          fn.call RDF::Statement.new(s.R, p.R,
                                     (o.class == WebResource || o.class == RDF::URI) ? o : (l = RDF::Literal (if p == Content
                                                                                                    R::HTML.strip o
                                                                                                   else
                                                                                                     o.gsub(/<[^>]*>/,' ')
                                                                                                    end)
                                                                                  l.datatype=RDF.XMLLiteral if p == Content
                                                                                  l), :graph_name => s.R)}
      end

      def resolveURIs *f
        send(*f){|s,p,o|
          if p==Content && o.class==String
            content = Nokogiri::HTML.fragment o
            content.css('img').map{|i|
              (i.attr 'src').do{|src|
                yield s, Image, src.R }}
            content.css('a').map{|a|
              (a.attr 'href').do{|href|
                link = s.R.join href
                a.set_attribute 'href', link
                yield s, DC+'link', link
                yield s, Image, link if %w{gif jpg png webp}.member? link.R.ext.downcase
              }}
            yield s, p, content.to_xhtml
          else
            yield s, p, o
          end
        }
      end

      def normalizePredicates *f
        send(*f){|s,p,o|
          yield s,
                {Atom+'content' => Content,
                 Atom+'displaycategories' => Label,
                 Atom+'enclosure' => SIOC+'attachment',
                 Atom+'link' => DC+'link',
                 Atom+'summary' => Abstract,
                 Atom+'title' => Title,
                 DCe+'subject' => Title,
                 DCe+'type' => Type,
                 Media+'title' => Title,
                 Media+'description' => Abstract,
                 Media+'community' => Content,
                 Podcast+'author' => Creator,
                 Podcast+'keywords' => Label,
                 Podcast+'subtitle' => Title,
                 YouTube+'videoId' => Label,
                 YouTube+'channelId' => SIOC+'user_agent',
                 RSS+'category' => Label,
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/content/encoded' => Content,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 RSS+'source' => DC+'source',
                 RSS+'title' => Title,
                }[p]||p, o }
      end

      def normalizeDates *f
        send(*f){|s,p,o|
          yield *({'CreationDate' => true,
                   'Date' => true,
                   RSS+'pubDate' => true,
                   Date => true,
                   DCe+'date' => true,
                   Atom+'published' => true,
                   Atom+'updated' => true
                  }[p] ?
                    [s,Date,Time.parse(o).utc.iso8601] : [s,p,o])}
      end

      def rawTriples
        # identifiers
        reRDF = /about=["']?([^'">\s]+)/              # RDF @about
        reLink = /<link>([^<]+)/                      # <link> element
        reLinkCData = /<link><\!\[CDATA\[([^\]]+)/    # <link> CDATA block
        reLinkHref = /<link[^>]+rel=["']?alternate["']?[^>]+href=["']?([^'">\s]+)/ # <link> @href @rel=alternate
        reLinkRel = /<link[^>]+href=["']?([^'">\s]+)/ # <link> @href
        reId = /<(?:gu)?id[^>]*>([^<]+)/              # <id> element
        # elements
        reHead = /<(rdf|rss|feed)([^>]+)/i
        reXMLns = /xmlns:?([a-z0-9]+)?=["']?([^'">\s]+)/
        reItem = %r{<(?<ns>rss:|atom:)?(?<tag>item|entry)(?<attrs>[\s][^>]*)?>(?<inner>.*?)</\k<ns>?\k<tag>>}mi
        reElement = %r{<([a-z0-9]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi
        reGroup = /<\/?media:group>/i
        # media elements
        reAttach = %r{<(link|enclosure|media|media:thumbnail)([^>]+)>}mi
        reSrc = /(href|url|src)=['"]?([^'">\s]+)/
        reRel = /rel=['"]?([^'">\s]+)/
        # XML namespaces
        x = {}
        head = @doc.match(reHead)
        head && head[2] && head[2].scan(reXMLns){|m|
          prefix = m[0]
          base = m[1]
          base = base + '#' unless %w{/ #}.member? base [-1]
          x[prefix] = base}
        @doc.scan(reItem){|m|
          attrs = m[2]
          inner = m[3]
          # find post identifier
          u = (attrs.do{|a|a.match(reRDF)} || inner.match(reLink) || inner.match(reLinkCData) || inner.match(reLinkHref) || inner.match(reLinkRel) || inner.match(reId)).do{|s|s[1]}
          if u
            u = (URI.join @base, u).to_s unless u.match /^http/
            resource = u.R
            yield u, Type, R[SIOC+'BlogPost']
            blogs = [resource.join('/')]
            blogs.push @base.R.join('/') if @base.R.host != resource.host
            blogs.map{|blog| yield u, R::To, blog}
            # links
            inner.scan(reAttach){|e|
              e[1].match(reSrc).do{|url|
                rel = e[1].match reRel
                rel = rel ? rel[1] : 'link'
                o = url[2].R
                p = case o.ext.downcase
                    when 'jpg'
                      R::Image
                    when 'png'
                      R::Image
                    else
                      R::Atom + rel
                    end
                yield u, p, o }}
            # XML elements
            inner.gsub(reGroup,'').scan(reElement){|e|
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1] # namespaced attribute-names
              if [Atom+'id',RSS+'link',RSS+'guid',Atom+'link'].member? p
              # used in subject URI search
              elsif [Atom+'author', RSS+'author', RSS+'creator', DCe+'creator'].member? p
                uri = e[3].match /<uri>([^<]+)</
                name = e[3].match /<name>([^<]+)</
                yield u, Creator, e[3].do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o } unless name||uri
                yield u, Creator, name[1] if name
                yield u, Creator, uri[1].R if uri
              else # generic element
                yield u,p,e[3].do{|o|
                  case o
                  when /^\s*<\!\[CDATA/m
                    o.sub /^\s*<\!\[CDATA\[(.*?)\]\]>\s*$/m,'\1'
                  when /</m
                    o
                  else
                    CGI.unescapeHTML o
                  end
                }.do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o }
              end
            }
          end}
      end
    end

    def renderFeed graph
      HTML.render ['<?xml version="1.0" encoding="utf-8"?>',
                   {_: :feed,xmlns: 'http://www.w3.org/2005/Atom',
                    c: [{_: :id, c: uri},
                        {_: :title, c: uri},
                        {_: :link, rel: :self, href: uri},
                        {_: :updated, c: Time.now.iso8601},
                        graph.map{|u,d|
                          {_: :entry,
                           c: [{_: :id, c: u}, {_: :link, href: u},
                               d[Date].do{|d|   {_: :updated, c: d[0]}},
                               d[Title].do{|t|  {_: :title,   c: t}},
                               d[Creator].do{|c|{_: :author,  c: c[0]}},
                               {_: :content, type: :xhtml,
                                c: {xmlns:"http://www.w3.org/1999/xhtml",
                                    c: d[Content]}}]}}]}]
    end
  end
  module Webize
    FeedNames = %w{atom atom.xml blog default feed feed.xml index.xml photos_public.gne news.rss news.xml .rss rss rss.xml RSS}
    def triplrOPML
      Nokogiri::HTML.fragment(readFile).css('outline[type="rss"]').map{|t|
        s = t.attr 'xmlurl'
        yield s, Type, R[SIOC+'Feed']
        yield s, Title, t.attr('title')
      }
    end
  end
end
