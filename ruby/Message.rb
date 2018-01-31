class WebResource

  module HTML

    def tableCellFromTo
      date = self[Date].sort[0]
      datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date
      [[Creator,SIOC+'addressed_to'].map{|edge|
         self[edge].map{|v|
           if v.respond_to?(:uri)
             v = v.R
             id = SecureRandom.hex 8
             if a SIOC+'MailMessage' # messages*address*month
               @r[:label][v.basename] = true
               R[v.path + '?head#r' + sha2].data({id: 'address_'+id, label: v.basename, name: v.basename}) if v.path
             elsif a SIOC+'Tweet'
               if edge == Creator  # tweets*author*day
                 @r[:label][v.basename] = true
                 R[datePath[0..-4] + '*/*twitter.com.'+v.basename+'*#r' + sha2].data({name: v.basename, label: v.basename})
               else # tweets*hour
                 R[datePath + '*twitter*#r' + sha2].data({label: '&#x1F425;'})
               end
             elsif a SIOC+'InstantMessage'
               if edge==From
                 nick = v.fragment
                 name = nick.gsub(/[_\-#@]+/,'')
                 @r[:label][name] = true
                 ((dir||self)+'?q='+nick).data({name: name, label: nick})
               elsif edge==To
                 v.data({label: CGI.unescape(basename).split('#')[-1]})
               end
             elsif (a SIOC+'BlogPost') && edge==To
               name = 'blog_'+(v.host||'').gsub('.','')
               @r[:label][name] = true
               R[datePath ? (datePath[0..-4] + '*/*' + (v.host||'') + '*#r' + sha2) : ('//'+host)].data({id: 'post'+id, label: v.host, name: name})
             elsif (a SIOC+'ChatLog') && edge==To
               name = v.basename[0..-2]
               @r[:label][name] = true
               v.data({name: name})
             else
               v
             end
           else
             {_: :span, c: (CGI.escapeHTML v.to_s)}
           end}.intersperse(' ')}.map{|a|a.empty? ? nil : a}.compact.intersperse(' &rarr; '),
       self[SIOC+'user_agent'].map{|a|['<br>',{_: :span, class: :notes, c: a}]}]
    end

  end

end
