WHAT? RDF-izers and a webserver for webmail, news-aggregation, filesystem-browsing, 

HISTORY
before Ruby had an RDF library, a format of "almost" RDF built on JSON was invented,
sans blank-nodes and advanced literal datatypes/languages (just JSON-native types).
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is swiftly-loading thousands of files for a sub-second response thanks to native a JSON-parse
and raw merging into RAM without the mapping/expansion steps of JSON-LD

this format now has a RDF::Reader class, to use in apps/servers like https://github.com/ruby-rdf/rdf-ldp
the long-tail non-RDF Formats are transcoded to this intermediate JSON format for speed on repeated reads.
our daemon does this by swapping out references to the non-RDF files with a reference to transcoded almost-RDF JSON files
or you can use RDF::Reader for non-RDF directly, without this optimization, see the Atom/RSS reader for examples

REQUISITES
Debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments

Voidlinux http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

 for mail, may also want msmtp, procmail, getmail (see conf/mail/)

INSTALL
 cd ruby
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE -> files in domain/hostname/path/to/file and/or path/to/file, the latter visible on any host
 cd ..
 cp conf/Procfile .
 foreman start # to listen on port 80/443 as non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
 
