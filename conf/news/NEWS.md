# NEWS

news means all new posts you might want to read, mostly firstly appearing on other servers unless you're a prolific journalist, fetched through RSS/Atom feeds, CSS-based scrapers, or 3rd-party APIs or NNTP. [MAIL](../mail/HOWTO) is another way news might arrive - everything is marked to a [SIOC](http://sioc-project.org/) schema for a generic message/post and we don't care how they originated.

# storage

the filesystem-db prefixes domain-names to the path in the URI to allow both virtual-hosting and mirroring of data from non-served (outside of our control) hosts. a brief introduction:

launch a REPL. if you don't have this library already installed [start here](../../README)

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

if you want to, you can write stuff to an appropriate path without using our tooling. for example to use **wget**, cd to domain/ and add the **-x** flag so directories are used

# timeline

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

you can link stuff here and it will show up. builtin feed functions do this automatically when indexing content.

as the default container-traverse is breadth-first, a [handler](../../ruby/message.news.rb.html) at /news configures to depth-first. this results in posts sorted on date-order. a date-offset can be provided in an **offset** argument in the query-string or in request-headers in the style of [Memento](http://mementoweb.org/about/). memento UI-tools allow you to see the news as-of a particular date via a calendar-interface rather than manual URL-hacking (which is supported and designed-for, if you prefer. just request a particular timeslice-container)


metadata in response-headers links to continued pages of content, enabling mirroring of the entire archive and a backing-substrate for "infinite-scroll" user-interfaces

# search

a **q** argument to the timeline causes a search to run. [example](http://b.whats-your.name/news/?q=cambridge)

# feeds

## discover
a nice side-effect of [Drupal](https://www.drupal.org/) and [Wordpress](https://wordpress.org/) providing a significant-portion of long-tail hosting is they provide a standard feed, taking out the guesswork of dealing with site-specific APIs. often times, the feed is simply at [/feed](http://b.whats-your.name/feed). if not, we've provided a resource-function named **feeds** which enumerates feeds mentioned in metadata-tags. you can use this from a REPL:

``` ruby
irb(main):001:0> 'http://b.whats-your.name/news/'.R.feeds
=> [#<RDF::URI:0x2b29b39b8ec8 URI:http://b.whats-your.name/feed/>]
```

or from a shell using the [R](../../ruby/R.html) resource-function

``` sh
~ R http://b.whats-your.name/news/ feeds
http://b.whats-your.name/feed/
```

## consume

a feed-parser is defined to [RDF](http://ruby-rdf.github.io/) library's Reader interface, so you can load a feed's current content into an RDF graph and use the full suite of RDF-libraries to do what you want with the data. we provide some functions: **getFeed** stores posts in local files, indexes them for search and links resources to the timeline, and **getFeeds** does this for a list of resources

``` sh
~ R http://b.whats-your.name/feed getFeed localhost
ix+ localhost http://www.reddit.com/r/boston/comments/43cyni/what_makes_you_uniquely_bostonian/
```

## produce

our handler at **/feed** fixes response MIME-type to **application/atom+xml** then defers to the timeline-handler. you can do a lot more than request the most recent 15 posts with it if you're an advanced user

``` sh
~ curl -I http://b.whats-your.name/feed/
HTTP/1.1 200 OK
Content-Type: application/atom+xml; charset=UTF-8
Link: </news/?set=page&c=20&desc&offset=//b.whats-your.name/news/2016/01/30/04/00:49.reddit.roxbury.43cjke.orchestra_in_the_hood_crowd_funding.n3>; rel=next
```