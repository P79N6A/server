class R

  GREP_DIRS.push(/^\/news\/\d{4}\/\d{2}/)

  GET['/news'] = -> d,e {
    location = d.justPath.docroot.uri
    newsloc = '/news'
    if location.downcase == newsloc # case-insensitive match
      if location != newsloc
        [301, {'Location' => newsloc}, []]
      else
        e[:Links][:alternate] = '/feed/?'+e['QUERY_STRING']
        if e.q.has_key?('q') # search query
          e.q['set'] ||= 'groonga'
        else # paged subtree
          e.q['set'] ||= 'page'
          e.q['c'] ||= 28
          # date-offsets as traversal-cursor (aka Memento)
          e['HTTP_ACCEPT_DATETIME'].do{|dt|
            t = Time.parse dt
            e[:Response]['Memento-Datetime'] = dt
            e.q['offset'] = d.join(t.strftime '%Y/%m/%d/').to_s}
        end
        nil
      end
    else
      nil
    end
  }

  GET['/feed'] = -> d,e {
    path = d.justPath.stripDoc.uri.sub /^\/feed\/?/,'' # eat host, ext, and /feed
    if path.empty? # serve feed
      e['HTTP_ACCEPT'] = 'application/atom+xml' # fix MIME
      e.q['set'] ||= 'page'; e.q['c'] ||= 15 # 15 posts in desc-date order
      d.dir.child('news').setEnv(e).response # request of news-container
    else # transcode feed
      if path.split('/').size > 1
        begin
          graph = RDF::Graph.new
          graph.load (e.scheme + '://' + path), :format => :feed
          [200, e[:Response].update({'Content-Type' => e.format}), [graph.dump(RDF::Writer.for(:content_type => e.format).to_sym)]]
        rescue
          E404[d,e]
        end
      else
        E404[d,e]
      end
    end}

  def getFeed h='localhost'
    store :format => :feed, :hook => FeedArchiverRDF, :hostname => h
    self
  rescue Exception => e
    puts [uri, e, e.message, e.backtrace]
  end
  def getFeeds h='localhost'
    uris.map{|u| u.R.getFeed h}
    nil
  end

  def listFeeds; (nokogiri.css 'link[rel=alternate]').map{|u|R (URI uri).merge(u.attr :href)} end
  alias_method :feeds, :listFeeds

  module Feed
    
    class Format < RDF::Format
      content_type     'application/atom+xml', :extension => :atom
      content_encoding 'utf-8'
      reader { R::Feed::Reader }
    end

    class Reader < RDF::Reader

      format Format

      def initialize(input = $stdin, options = {}, &block)
        @doc = (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
        if block_given?
          case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
          end
        end
        nil
      end
      
      def each_statement &fn
        dateNormalize(:resolveURIs,:mapPredicates,:rawFeedTriples){|s,p,o| # triple-stream massager stack
          fn.call RDF::Statement.new(s.R, p.R,
                                     o.class == R ? o : (l = RDF::Literal (if p == Content
                                                                             R::StripHTML[o]
                                                                           else
                                                                             o.gsub(/<[^>]*>/,' ')
                                                                           end)
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l),
                                     :context => s.R.docroot)}
      end

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
      end

      def resolveURIs *f
        send(*f){|s,p,o|
          yield s, p, p == Content ?
          (Nokogiri::HTML.fragment o).do{|o|
            o.css('a').map{|a|
              if a.has_attribute? 'href'
                (a.set_attribute 'href', (URI.join s, (a.attr 'href'))) rescue nil
              end}
            o.to_xhtml} : o}
      end

      def mapPredicates *f
        send(*f){|s,p,o|
          if ['http://search.yahoo.com/mrss/content', 'http://wellformedweb.org/CommentAPI/commentRss', RSS+'guid', RSS+'link', RSS+'comments', SIOC+'num_replies'].member? p
            
          else
            yield s,
                  { Purl+'dc/elements/1.1/creator' => Creator,
                    Purl+'dc/elements/1.1/subject' => SIOC+'subject',
                    Atom+'author' => Creator,
                    RSS+'description' => Content,
                    RSS+'encoded' => Content,
                    RSS+'modules/content/encoded' => Content,
                    RSS+'modules/slash/comments' => SIOC+'num_replies',
                    Atom+'content' => Content,
                    Atom+'summary' => Content,
                    RSS+'title' => Title,
                    Atom+'title' => Title,
                  }[p] || p, o
          end
        }
      end

      def rawFeedTriples
        x = {} # XML-namespace table
        head = @doc.match(/<(rdf|rss|feed)([^>]+)/i)
        head && head[2] && head[2].scan(/xmlns:?([a-z]+)?=["']?([^'">\s]+)/){|m|
          prefix = m[0]
          base = m[1]
          base = base + '#' unless %w{/ #}.member? base [-1]
          x[prefix] = base}

        # resources
        @doc.scan(%r{<(?<ns>rss:|atom:)?(?<tag>item|entry)(?<attrs>[\s][^>]*)?>(?<inner>.*?)</\k<ns>?\k<tag>>}mi){|m|
          # identifier search
          attrs = m[2]
          inner = m[3]
          u = attrs.do{|a| # RDF-style identifier (RSS 1.0)
            a.match(/about=["']?([^'">\s]+)/).do{|s|
              s[1] }} ||
          (inner.match(/<link>([^<]+)/) || # <link> child-node or href attribute
           inner.match(/<link[^>]+rel=["']?alternate["']?[^>]+href=["']?([^'">\s]+)/) ||
           inner.match(/<(?:gu)?id[^>]*>([^<]+)/)).do{|s| s[1]} # <id> child 

          if u
            if !u.match /^http/
              u = '/junk/'+u.gsub('/','.')
            end
            yield u, R::Type, R[R::BlogPost]
            yield u, To, u.R

            #links
            inner.scan(%r{<(link|enclosure|media)([^>]+)>}mi){|e|
              e[1].match(/(href|url|src)=['"]?([^'">\s]+)/).do{|url|
                yield(u,R::Atom+((r=e[1].match(/rel=['"]?([^'">\s]+)/)) ? r[1] : e[0]), url[2].R)}}

            #elements
            inner.scan(%r{<([a-z]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi){|e|
              yield u,                           # s
              (x[e[0] && e[0].chop]||R::RSS) + e[1], # p
           e[3].extend(SniffContent).sniff.do{|o|# o
                o.match(HTTP_URI) ? o.R : o
              }}
          end
        }

      end
      
      def dateNormalize *f
        send(*f){|s,p,o|
          yield *({'CreationDate' => true,
                    'Date' => true,
                    RSS+'pubDate' => true,
                    Date => true,
                    Purl+'dc/elements/1.1/date' => true,
                    Atom+'published' => true,
                    Atom+'updated' => true
                  }[p] ?
                  [s,Date,Time.parse(o).utc.iso8601] : [s,p,o])}
      end

    end

    module SniffContent

      def sniff
        send (case self
              when /^\s*<\!/m
                :cdata
              when /</m
                :id
              else
                :html
              end)
      end

      def html
        CGI.unescapeHTML self
      end

      def cdata
        sub /^\s*<\!\[CDATA\[(.*?)\]\]>\s*$/m,'\1'
      end

    end

  end

  def triplrFeed
    RDF::Reader.open(pathPOSIX, :format => :feed){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, o.class == R ? o : o.value}}
  end

  FeedStop = /\b(at|blog|com(ments)?|html|info|org|photo|p|post|r|status|tag|twitter|wordpress|www|1999|2005)\b/

  FeedArchiverJSON = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t|
        t = t[0].gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        b = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.' # derive basename
        doc.ln R["//#{host}/news/#{t}#{b}e"]}} # link to timeline
    doc}

  FeedArchiverRDF = -> doc, graph, host {
    doc.roonga host
    graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|
      time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # trim normalized timezones
      base = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
      doc.ln R["//#{host}/news/#{time}#{base}n3"]}}

  Render['application/atom+xml'] = -> d,e {
    id = '//' + e.host + (CGI.escapeHTML e['REQUEST_URI'])
    H(['<?xml version="1.0" encoding="utf-8"?>',
       {_: :feed,xmlns: 'http://www.w3.org/2005/Atom',
         c: [{_: :id, c: id},
             {_: :title, c: id},
             {_: :link, rel: :self, href: id},
             {_: :updated, c: Time.now.iso8601},
             d.map{|u,d|
               d[Content] &&
               {_: :entry,
                 c: [{_: :id, c: u},
                     {_: :link, href: d.uri},
                     d[Date].do{|d|{_: :updated, c: d[0]}},
                     d[Title].do{|t|{_: :title, c: t}},
                     d[Creator].do{|c|{_: :author, c: c[0]}},
                     {_: :content, type: :xhtml,
                       c: {xmlns:"http://www.w3.org/1999/xhtml",
                           c: d[Content]}}].cr}}.cr]}])}

end
