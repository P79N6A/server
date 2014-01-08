watch __FILE__
class E

  F['view/'+SIOCt+'BlogPost']=->g,e{
    g.map{|u,r|
      if u.match /universalhub/
        {c: [{_: :a, href: r['http://purl.org/rss/1.0/link'][0],
               c: [{_: :img, src: '/logos/uhub.png',style: 'position:absolute;top:-93px'},
                   {_: :h2, style: 'color:#000;margin:0',c: r[Title]}]},
             r[Content]
            ],
          style: 'float:left;max-width:40em;position:relative;background-color:#fff;border-color:#eee;margin-top:93px;padding-top:0;border-style:dotted;border-width:.3em;border-radius:0 .8em .8em .8em'
        }
      else
        r.html
      end
    }
  }

end
