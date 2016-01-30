# NEWS

news means all new posts you might want to read, mostly firstly appearing on other servers unless you are a prolific journalist, fetched through RSS/Atom feeds, CSS-based scrapers, or 3rd-party APIs or NNTP. [Mail](../mail/HOWTO) is another way news might arrive - everything is marked to a [SIOC](http://sioc-project.org/) schema for a generic message/post and we don't care how they originated.

## storage

our filesystem-db prefixes domain-names to the path-part of the URI, to allow both virtual-hosting and caching of data from non-served hosts (outside of our control). a brief introduction:

launch a REPL:

``` sh
irb -rww
```

find all posts in a domain:

``` ruby
irb(main):007:0> articles = R('//datatherapy.org').take
=> [#<RDF::URI:0x547a25c URI://datatherapy.org/2016/01/18/talking-visualization-literacy-at-rdfviz.n3>, #<RDF::URI:0x5479212 URI://datatherapy.org/2015/07/23/architectures-for-data-use.n3>, #<RDF::URI:0x547905a URI://datatherapy.org/2015/07/21/telling-stories-with-data-presentation.n3>]
```

inspect a post:

``` ruby
irb(main):010:0> post = articles[0]
=> #<RDF::URI:0x546f302 URI://datatherapy.org/2016/01/18/talking-visualization-literacy-at-rdfviz.n3>
irb(main):012:0> post.pathPOSIX
=> "/var/www/domain/datatherapy.org/2016/01/18/talking-visualization-literacy-at-rdfviz.n3"
```

if you want to, you can write stuff to an appropriate path without using our tooling. for example to use **wget**, cd to domain/ and add the -x flag so that directories are used

in this directory are some sample scripts to archive news from 3rd-party sources

a hostname argument directs the indexing and linkage to a timeline at $host/news
