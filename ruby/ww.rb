%w{cgi csv date digest/sha2 dimensions fileutils icalendar json linkeddata mail nokogiri open-uri pathname rack rdf redcarpet resolv-replace shellwords}.map{|r|require r}
%w{URI MIME HTTP HTML POSIX Feed JSON Text Mail Calendar Chat Icons Image AdHoc}.map{|i|require_relative i}
R = WebResource
