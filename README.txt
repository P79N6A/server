a subset of RDF in JSON is our intermediary format,
no blank-nodes, advanced literal datatypes/languages (just JSON-native types), or prefix-expansioned prediccate-URIs.
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is loading thousands of files in a sub-second response w/ native-stdlib JSON-parsers vs pure-ruby RDF-parsers,
and a model allowing trivial "hash merge" into RAM without the mapping/expansion/rewriting steps of JSON-LD.

i wouldnt recommend using this server unless you know what you're doing. it's in the process of being deleted. 
i mainly just wanted something low-hassle and minimal to read mail and news. it predates RDF.rb and maybe even Rails.
first we erased manual sprintf()'ing to a socket with Rack, when that came along. then later a RDF::Reader was written
so we can use our speed-oriented subset in full RDF Graphs and apps, and next i'll proably delete the daemon and 
figure out how to hook in the RDF-izers behind the Non-RDF hooks in lamprey from https://github.com/ruby-rdf/rdf-ldp
it's been in the process of deletion for 12 years and one day hopefully it will be entirely gone! 

REQUISITES
Debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments

Voidlinux http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

INSTALL
 cd ruby
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE -> files in domain/hostname/path/to/file and/or path/to/file, latter visible to any host
 cd ..
 cp conf/Procfile .
 foreman start # listen on port 80/443 as non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
 # you can use nginx/apache do <1024 and bind to a high-port. or throw us behind a 404-handler on a LDP server, or..
 # mail-paths start with /address or /thread so just those paths could be sent in, etc..
