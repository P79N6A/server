# coding: utf-8
class WebResource
  module HTML

    def htmlTable graph
      (1..10).map{|i|@r[:label]["quote"+i.to_s] = true} # labels
      [:links,:images].map{|p|@r[p] = []} # link & image lists
      p = q['sort'] || Date
      direction = q.has_key?('ascending') ? :id : :reverse
      datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
      keys = graph.values.map(&:keys).flatten.uniq - InlineMeta
      keys -= VerboseMeta unless q.has_key? 'full'
      [{_: :table,
        c: [{_: :tbody,
             c: graph.values.sort_by{|s|((p=='uri' ? (s[Title]||s[Label]||s.uri) : s[p]).justArray[0]||0).send datatype}.
               send(direction).map{|r|
               r.R.environment(@r).tableRow p,direction,keys unless r.keys==%w{uri}}},
            {_: :tr, c: [From,Type,'uri',*keys,DC+'cache',Date,Size].map{|k| # header row
               selection = p == k
               q_ = q.merge({'sort' => k})
               if direction == :id # direction toggle
                 q_.delete 'ascending'
               else
                 q_['ascending'] = ''
               end
               href = CGI.escapeHTML HTTP.qs q_
               {_: :th, property: k, class: selection ? 'selected' : '',
                c: [{_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)},
                    (selection ? {_: :link, rel: :sort, href: href} : '')]}}}]},
       {_: :style, c: "[property=\"#{p}\"] {border-color:#444;border-style: solid; border-width: 0 0 .08em 0}"}]
    end

    def tableRow sort,direction,keys
      hidden = q.has_key?('head') && self[Title].empty? && self[Abstract].empty? && self[Link].empty?
      hidden ? '' : {_: :tr,
                     c: [{_: :td, class: :fromTo, c: tableCellFromTo},
                         {_: :td, c: tableCellTypes},
                         {_: :td, c: tableCellMain},
                         keys.map{|k|
                           {_: :td, property: k,
                            c: self[k].map{|v|
                              v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')}},
                         {_: :td, c: tableCellCache},
                         {_: :td, c: tableCellDate},
                         {_: :td, c: tableCellSize}]}
    end

    def tableCellMain
      [tableCellLabels,
       tableCellTitle,
       tableCellAbstract,
       tableCellLinks,
       tableCellContent,
       tableCellPhoto,
       tableCellVideo]
    end

    def tableCellContent
      self[Content].map{|c|
        if (a SIOC+'SourceCode') || (a SIOC+'MailMessage')
          {_: :pre, c: c}
        elsif a SIOC+'InstantMessage'
          {_: :span, class: :monospace, c: c}
        else
          c
        end
      }.intersperse(' ') unless q.has_key?('head')
    end

  end
  module Webize
    def triplrCSV d
      ns    = W3 + 'ns/csv#'
      lines = CSV.read localPath
      lines[0].do{|fields| # header-row
        yield uri, Type, R[ns+'Table']
        yield uri, ns+'rowCount', lines.size
        lines[1..-1].each_with_index{|row,line|
          row.each_with_index{|field,i|
            id = uri + '#row:' + line.to_s
            yield id, fields[i], field
            yield id, Type, R[ns+'Row']}}}
    end
  end
end
