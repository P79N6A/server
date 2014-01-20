#watch __FILE__

module FeedParse

  def html; CGI.unescapeHTML self end
  def cdata; sub /^\s*<\!\[CDATA\[(.*?)\]\]>\s*$/m,'\1'end
  def guess; send (case self
                   when /^\s*<\!/m
                     :cdata
                   when /</m
                     :id
                   else
                     :html
                   end) end

  def parse

    x={} #prefix table
    match(/<(rdf|rss|feed)([^>]+)/i)[2].scan(/xmlns:?([a-z]+)?=["']?([^'">\s]+)/){|m|x[m[0]]=m[1]}

    #items
    scan(%r{<(rss:|atom:)?(item|entry)([\s][^>]*)?>(.*?)</\1?\2>}mi){|m|

      # identifier select -> RDF URI || <id> || <link>
      u = m[2] && (u = m[2].match /about=["']?([^'">\s]+)/) && u[1] ||
          m[3] && (((u = m[3].match /<(gu)?id[^>]*>([^<]+)/) || (u = m[3].match /<(link)>([^<]+)/)) && u[2])

      yield u, E::Type, (E::SIOCt+'BlogPost').E
      yield u, E::Type, (E::SIOC+'Post').E

      #links
      m[3].scan(%r{<(link|enclosure|media)([^>]+)>}mi){|e|
        e[1].match(/(href|url|src)=['"]?([^'">\s]+)/).do{|url|
          yield(u,E::Atom+'/link/'+((r=e[1].match(/rel=['"]?([^'">\s]+)/)) ? r[1] : e[0]), url[2].E)}}

      #elements
      m[3].scan(%r{<([a-z]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi){|e|
        yield u,                           # s
        (x[e[0]&&e[0].chop]||E::RSS)+e[1], # p
        e[3].extend(FeedParse).guess.do{|o|# o
          o.match(/\A(\/|http)[\S]+\Z/) ? o.E : o
        }}}
    
    nil
  end
end

class E

  Atom = W3+'2005/Atom'
   RSS = Purl+'rss/1.0/'
  RSSm = RSS+'modules/'
  Feed = (E RSS+'channel')

  def listFeeds; (nokogiri.css 'link[rel=alternate]').map{|u|E (URI uri).merge(u.attr :href)} end
  alias_method :feeds, :listFeeds

  FeedArchiver = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t| # link doc to date-index
        t = t[0].gsub(/[-T]/,'/').sub /(.00.00|Z)$/, '' # trim normalized timezones
        b = (u.sub(/^http.../,'').gsub('/','.').gsub(/(com|org|status|twitter|www)\./,'').sub(/\d{8,}/,'')+'.').gsub /\.+/,'.' # derive a unique basename
        doc.ln E["http://#{host}/news/#{t}.#{b}e"]}}}

  GREP_DIRS.push /^\/news\/\d{4}/

  def getFeed       g; addDocs :triplrFeed, g, nil, FeedArchiver end
  def getFeedReddit g; addDocs :triplrFeedReddit, g, nil, FeedArchiver end

  def triplrFeed &f 
    dateNorm :contentURIresolve,:triplrFeedNormalize,:triplrFeedRaw,&f
  end

  def triplrFeedReddit &f
    triplrFeed {|s,p,o|
     p == Content ?
      Nokogiri::HTML.parse(o).do{|o|
        o.css('.md').do{|o|yield s,p,o}
        yield s,Creator,o.css('a')[-4].child.to_s.strip
        yield s,Type,(SIOCt+'BoardPost').E
      } : (yield s,p,o)}
  end

  def triplrFeedRaw &f
    read.to_utf8.extend(FeedParse).parse &f
  rescue Exception => e
    puts [uri,e,e.backtrace[0]].join ' '
  end

  def triplrFeedNormalize *f
    send(*f){|s,p,o|
      yield s,
      { Purl+'dc/elements/1.1/creator' => Creator,
        Purl+'dc/elements/1.1/subject' => SIOC+'subject',
        Atom+'author' => Creator,
        RSS+'description' => Content,
        RSS+'encoded' => Content,
        RSSm+'content/encoded' => Content,
        Atom+'content' => Content,
        RSS+'title' => Title,
        Atom+'title' => Title,
      }[p]||p,
      o } end

  fn Render+'application/atom+xml',->d,e{
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
                         c: d[Content]}}].cr
               }}.cr
            ]}])}

end
