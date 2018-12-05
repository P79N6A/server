class WebResource
  module Webize

    def indexRDF options = {}
      newResources = []
      # load resource
      g = RDF::Repository.load self, options
      # visit named-graph resources
      g.each_graph.map{|graph|
        # find timestamp for timeline-linkage
        graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|

          # mint document-URI
          time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
          doc =  R["/#{time}#{slug}.ttl"]

          unless doc.e # TODO timestamp-check and archival for updates without a URI change
            doc.dir.mkdir
            resource = doc.stripDoc
            graph << RDF::Statement.new(graph.name, R[Cache], resource)
            RDF::Writer.open(doc.localPath){|f|f << graph}
            puts "http://localhost" + resource
            newResources << doc
          end
          true}}

      newResources
    rescue Exception => e
      puts uri, e.class, e.message
    end
  end
end
