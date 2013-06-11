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

  def parse # Universal feed-parser

    #xml qname table
    x={}
    match(/<(rdf|rss|feed)([^>]+)/i)[2].scan(/xmlns:?([a-z]+)?=["']?([^'">\s]+)/){|m|x[m[0]]=m[1]}

    #items
    scan(%r{<(rss:|atom:)?(item|entry)([\s][^>]*)?>(.*?)</\1?\2>}mi){|m|

      #URI
      u = m[2] && (u=m[2].match /about=["']?([^'">\s]+)/) && u[1] ||
          m[3] && (((u=m[3].match /<(gu)?id[^>]*>([^<]+)/) || (u=m[3].match /<(link)>([^<]+)/)) && u[2])
      yield u,E::Type,(E::SIOC+'Post').E

      #links
      m[3].scan(%r{<(link|enclosure|media)([^>]+)>}mi){|e|
        yield(u,                                                                       # s
              E::Atom+'/link/'+((r=e[1].match(/rel=['"]?([^'">\s]+)/)) ? r[1] : e[0]), # p
              e[1].match(/(href|url|src)=['"]?([^'">\s]+)/)[2].E)}                     # o

      #elements
      m[3].scan(%r{<([a-z]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi){|e|
        yield u,                           # s
        (x[e[0]&&e[0].chop]||E::RSS)+e[1], # p
        e[3].extend(FeedParse).guess}}     # o
    
    nil
  end
end

class E
  Feed = (E RSS+'channel')

  def feeds; (nokogiri.css 'link[rel=alternate]').map{|u|E (URI uri).merge(u.attr :href)} end
  def getFeed g; addJSON :triplrFeed,g end
  def getFeedReddit g; addJSON :triplrFeedReddit,g end

  # tripleStream
  def triplrFeed &f 
    dateNorm :triplrFeedSIOCize,:triplrFeedRaw,&f
  rescue Exception => x
  end

  def triplrFeedReddit &f
    require 'nokogiri'
    triplrFeed {|s,p,o|
     p == Content ?
      Nokogiri::HTML.parse(o).do{|o|
        o.css('.md').do{|o|yield s,p,o}
        yield s,Creator,o.css('a')[-4].child.to_s.strip
      } : (yield s,p,o)}
  end

  # tripleStream
  def triplrFeedRaw &f
    read.extend(FeedParse).parse &f
  end

  # tripleStream -> tripleStream
  def triplrFeedSIOCize *f
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
                       c: {xmlns:"http://www.w3.org/1999/xhtml", c: d[Content]}}
                    ].intersperse("\n")}
             }.intersperse("\n")]}])}

end
