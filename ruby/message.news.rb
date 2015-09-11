#watch __FILE__
class R

  GET['/news'] = -> d,e {
    if d.path == '/news/'
      e[:Links][:alternate] = '/feed/?'+e['QUERY_STRING']
      if e.q.has_key?('q') # search
        e.q['set'] = 'groonga'
      else # subtree
        e.q['set'] = 'page'
        e.q['c'] ||= 22
        e['HTTP_ACCEPT_DATETIME'].do{|dt|
          t = Time.parse dt
          e[:Response]['Memento-Datetime'] = dt
          e.q['offset'] = d.join(t.strftime '%Y/%m/%d/').to_s}
      end
      nil
    end}

  GET['/feed'] = -> d,e {
    e[:nosummary] = true                      # don't group/filter
    e['HTTP_ACCEPT'] = 'application/atom+xml' # set feed MIME
    e.q['set'] = 'page'                       # paginate news/ container
    e.q['c'] ||= 20                           # post-count
    d.dir.child('news/').setEnv(e).response}  # return

  def getFeed h='localhost'
    puts "fetch #{uri}"
    store :format => :feed, :hook => IndexFeedRDF, :hostname => h
    self
  rescue Exception => e
    puts uri, e, e.message
  end
  def getFeeds h='localhost'
    uris.map{|u|
      u.R.getFeed h}
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
        dateNormalize(:massage,:mapPredicates,:rawFeedTriples){|s,p,o| # triple-stream transform pipeline
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

      def massage *f
        send(*f){|s,p,o|
          content = p == Content

          reddit = s.R.host.match(/reddit\.com$/)
          # TODO host-specific hooks

          # predicate-specific extractions
          if content
            submission = /.* submitted by /
            if reddit && o.match(submission)
              (Nokogiri::HTML.fragment o.sub(submission,' ')).do{|o|
                links = o.css('a')
                yield s, Creator, R[links[0].attr('href')]
                yield s, To, R[links[1].attr('href')]
              }
            else
              yield s, To, s.R.hostPart.R
            end
          elsif p == Title
            if reddit
              authorTitleRe = /^(\S+) on /
              authorTitle = o.match authorTitleRe
              if authorTitle
                yield s, Creator, R['https://reddit.com/u/'+authorTitle[1]]
              end
            end
          end

          # resolve URIs relative to origin doc
          yield s, p, content ?
          (Nokogiri::HTML.fragment o).do{|o|
            o.css('a').map{|a|
              if a.has_attribute? 'href'
                (a.set_attribute 'href', (URI.join s, (a.attr 'href'))) rescue nil
              end}
            o.to_xhtml} : o

        }
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

  IndexFeedJSON = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t|
        t = t[0].gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # iso8601 to date-path, for timeline
        b = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.' # clean name slug
        doc.ln R["//#{host}/news/#{t}#{b}e"]}} # link to timeline
    doc}

  IndexFeedRDF = -> doc, graph, host {
    doc.roonga host
    graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|
      time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # trim normalized timezones
      base = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
      doc.ln R["//#{host}/news/#{time}#{base}n3"]}} # link

  Render['application/atom+xml'] = -> d,e {
    id = '//' + e.host + (CGI.escapeHTML e['REQUEST_URI'])
    H(['<?xml version="1.0" encoding="utf-8"?>',
       {_: :feed,xmlns: 'http://www.w3.org/2005/Atom',
         c: [{_: :id, c: id},
             {_: :title, c: id},
             {_: :link, rel: :self, href: id},
             {_: :updated, c: Time.now.iso8601},
             d.map{|u,d|
               {_: :entry,
                 c: [{_: :id, c: u}, {_: :link, href: u},
                     d[Date].do{|d|   {_: :updated, c: d[0]}},
                     d[Title].do{|t|  {_: :title,   c: t}},
                     d[Creator].do{|c|{_: :author,  c: c[0]}},
                     {_: :content, type: :xhtml,
                       c: {xmlns:"http://www.w3.org/1999/xhtml",
                           c: d[Content]}}]}}]}])}

end
