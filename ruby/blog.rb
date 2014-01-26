#watch __FILE__
class E

  F['view/'+SIOCt+'BlogPost']=->g,e{

    F['example/blogview'][g,e]

  }

  F['example/blogview']=->g,e{
    g.map{|u,r|
      case u
      when /artery.wbur/ # compact whitespace a bit
        r[Content] = {class: :WBUR, c: [{_: :style, c: ".WBUR p {margin:0}"},r[Content]]}
        F['view/base'][{u => r},e,false]        
      when /boston\.com/ # crop sharebuttons
       (Nokogiri::HTML.parse r[Content][0]).css('p')[0].do{|p|r[Content]=p.inner_html}
        F['view/base'][{u => r},e,false]
      when /flickr/
        r[Content]
      when /reddit/ # minimal view
        F['view/'+SIOCt+'BoardPost'][{u => r},e]
      when /universalhub/  # logo + trim spacehogging tagjunk
        c = Nokogiri::HTML.fragment r[Content][0]
        c.css('section').map{|x|x.remove}
        {c: [{_: :a, href: r['http://purl.org/rss/1.0/link'][0].E.uri,
               c: [{_: :img, src: '/logos/uhub.png',style: 'position:absolute;top:-93px'},
                   {_: :h2, style: 'color:#000;margin:0',c: r[Title]}]},c.to_s],
          style: 'float:left;max-width:40em;position:relative;background-color:#fff;border-color:#eee;margin-top:93px;margin-right:.3em;padding-top:0;border-style:dotted;border-width:.3em;border-radius:0 .8em .8em .8em'}
      else
        F['view/base'][{u => r},e]
      end}}

end
