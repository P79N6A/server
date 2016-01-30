# NEWS

news means all new posts you might want to read, mostly firstly appearing on other servers unless you're a prolific journalist, fetched through RSS/Atom feeds, CSS-based scrapers, or 3rd-party APIs or NNTP. [Mail](../mail/HOWTO) is another way news might arrive - everything is marked to a [SIOC](http://sioc-project.org/) schema for a generic message/post and we don't care how they originated.

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

## timeline

in addition to storage at host-specific URI, posts are hardlinked to a timeline location, which is a path traversible on date-components. multiple hosts in a timeline and possibly multiple timelines on a server. as a consequence of allowing multiple timelines, a host-argument is required to provide a context for timeline-related operations.

``` ruby
irb(main):001:0> timeline = '//b.whats-your.name/news'.R
=> #<RDF::URI:0x57932a4 URI://b.whats-your.name/news>
irb(main):002:0> years = timeline.c
=> [#<RDF::URI:0x578353e URI://b.whats-your.name/news/2014>, #<RDF::URI:0x578343a URI://b.whats-your.name/news/2015>, #<RDF::URI:0x5783318 URI://b.whats-your.name/news/2016>]
irb(main):003:0> months = years[-1].c
=> [#<RDF::URI:0x5780e6a URI://b.whats-your.name/news/2016/01>]
irb(main):004:0> days = months[-1].c
=> [#<RDF::URI:0x577bd48 URI://b.whats-your.name/news/2016/01/21>, #<RDF::URI:0x577bbb8 URI://b.whats-your.name/news/2016/01/22>]
irb(main):005:0> hours = days[-1].c
=> [#<RDF::URI:0x5768efa URI://b.whats-your.name/news/2016/01/13/21>, #<RDF::URI:0x5768c84 URI://b.whats-your.name/news/2016/01/13/22>]

```

you can hard-link stuff here and it will show up. builtin feed functions do this automatically when indexing content.

as the default container-traverse is breadth-first, a [handler](../../ruby/message.news.rb.html) at /news configures to depth-first. this results in posts sorted on date-order. a date-offset can be provided in the querystring in **offset** parameter or request-header in the style of [Memento](http://mementoweb.org/about/). memento UI-tools allow you to see the news as-of a particular date via a calendar-interface rather than manual URL-hacking (which is supported and designed-for, if you prefer. just request a particular timeslice-container)

## search

a **q** argument to the timeline causes a search to run. [example](http://b.whats-your.name/news/?q=cambridge)

## fetch

