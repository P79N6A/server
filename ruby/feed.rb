#watch __FILE__
class R

  GET['/news'] = -> d,e {
    if %w{/news /news/ /news/index.n3 /news.n3}.member? d.pathSegment
      e.q['set'] ||= 'depth' # post-range in date-order
      e.q['local'] ||= true  # hostname-specific
      e.q['c'] ||= 32        # page size
      e.q.delete 'view' if e.q['view'] == 'ls' # strip fs-view
      R['http://'+e['SERVER_NAME']+'/news'].env(e).response # continue
    end}

  GET['/news.n3'] = GET['/news']

  def getFeed h='localhost'; addDocsRDF :format => :feed, :hook => FeedArchiverRDF, :hostname => h end
  def getFeeds h='localhost'; uris.map{|u| u.R.getFeed h} end

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
        dateNormalize(:resolveURIs,:mapPredicates,:rawFeedTriples){|s,p,o|
          fn.call RDF::Statement.new(s.R, p.R,
                                     o.class == R ? o : (l = RDF::Literal o
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l),
                                     :context => s.R.stripDoc)} end

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
            o.to_s} : o}
      end

      def mapPredicates *f
        send(*f){|s,p,o|
          yield s,
          { Purl+'dc/elements/1.1/creator' => Creator,
            Purl+'dc/elements/1.1/subject' => SIOC+'subject',
            Atom+'author' => Creator,
            RSS+'description' => Content,
            RSS+'encoded' => Content,
            RSS+'modules/content/encoded' => Content,
            Atom+'content' => Content,
            RSS+'title' => Title,
            Atom+'title' => Title,
          }[p]||p,
          o }
      end

      def rawFeedTriples
        x={} #XMLns prefix table
        @doc.match(/<(rdf|rss|feed)([^>]+)/i)[2].scan(/xmlns:?([a-z]+)?=["']?([^'">\s]+)/){|m|x[m[0]]=m[1]}

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
            yield u, R::Type, (R::SIOCt+'BlogPost').R
            yield u, R::Type, (R::SIOC+'Post').R
            
            #links
            inner.scan(%r{<(link|enclosure|media)([^>]+)>}mi){|e|
              e[1].match(/(href|url|src)=['"]?([^'">\s]+)/).do{|url|
                yield(u,R::Atom+'/link/'+((r=e[1].match(/rel=['"]?([^'">\s]+)/)) ? r[1] : e[0]), url[2].R)}}

            #elements
            inner.scan(%r{<([a-z]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi){|e|
              yield u,                           # s
              (x[e[0]&&e[0].chop]||R::RSS)+e[1], # p
           e[3].extend(SniffContent).sniff.do{|o|# o
                o.match(/\A(\/|http)[\S]+\Z/) ? o.R : R::CleanHTML[o]
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

  FeedStop = /\b(at|blog|com(ments)?|html|info|org|photo|p|post|r|status|tag|twitter|wordpress|www|1999|2005)\b/

  FeedArchiverJSON = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t| # link doc to date-index
        t = t[0].gsub(/[-T]/,'/').sub /(.00.00|Z)$/, '' # trim normalized timezones and non-unique symbols
        b = (u.sub(/http:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
        doc.ln R["http://#{host}/news/#{t}#{b}e"]}}
    doc}

  FeedArchiverRDF = -> doc, graph, host {
    doc.roonga host
    graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|
      time = t.gsub(/[-T]/,'/').sub /(.00.00|Z)$/, '' # trim normalized timezones
      base = (graph.name.to_s.sub(/http:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
      doc.ln R["http://#{host}/news/#{time}#{base}n3"]}}

  GREP_DIRS.push /^\/news\/\d{4}/

  Render['application/atom+xml'] = -> d,e {
    id = 'http://' + e['SERVER_NAME'] + (CGI.escapeHTML e['REQUEST_URI'])
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
                     {_: :link, href: d.url},
                     d[Date].do{|d|{_: :updated, c: d[0]}},
                     d[Title].do{|t|{_: :title, c: t}},
                     d[Creator].do{|c|{_: :author, c: c[0]}},
                     {_: :content, type: :xhtml,
                       c: {xmlns:"http://www.w3.org/1999/xhtml",
                         c: d[Content]}}].cr}}.cr]}])}

  def checkURIs
    r = uris.map{|u|
      c = [`curl -IsA 404? "#{u}"`.lines.to_a[0].match(/\d{3}/)[0].to_i,u] # HEAD
      puts c.join ' ' 
      c } # status, uri tuple
    puts "\n\n"
    r.map{|c| # inspect anomalies
      puts c.join(' ') unless c[0] == 200 }
  end

end
