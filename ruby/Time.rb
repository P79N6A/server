class WebResource
  module HTTP

    def dateMeta
      dp = [] # date parts
      dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
      n = nil; p = nil
      case dp.length
      when 1 # Y
        year = dp[0]
        n = '/' + (year + 1).to_s
        p = '/' + (year - 1).to_s
      when 2 # Y-m
        year = dp[0]
        m = dp[1]
        n = m >= 12 ? "/#{year + 1}/#{01}" : "/#{year}/#{'%02d' % (m + 1)}"
        p = m <=  1 ? "/#{year - 1}/#{12}" : "/#{year}/#{'%02d' % (m - 1)}"
      when 3 # Y-m-d
        day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
        if day
          p = (day-1).strftime('/%Y/%m/%d')
          n = (day+1).strftime('/%Y/%m/%d')
        end
      when 4 # Y-m-d-H
        day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
        if day
          hour = dp[3]
          p = hour <=  0 ? (day - 1).strftime('/%Y/%m/%d/23') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour-1)))
          n = hour >= 23 ? (day + 1).strftime('/%Y/%m/%d/00') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour+1)))
        end
      end
      # preserve trailing slash
      sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '')

      # add pointers to HTTP response header
      @r[:links][:prev] = p + '/' + parts.join('/') + sl + qs + '#prev' if p && R[p].e
      @r[:links][:next] = n + '/' + parts.join('/') + sl + qs + '#next' if n && R[n].e
      @r[:links][:up] = dirname + (dirname == '/' ? '' : '/') + qs + '#r' + path.sha2 unless path=='/'
    end

    def chronoDir ps
      time = Time.now
      loc = time.strftime(case ps[0][0].downcase
                          when 'y'
                            '%Y'
                          when 'm'
                            '%Y/%m'
                          when 'd'
                            '%Y/%m/%d'
                          when 'h'
                            '%Y/%m/%d/%H'
                          else
                          end)
      [303,@r[:Response].update({'Location' => '/' + loc + '/' + ps[1..-1].join('/') + qs}),[]]
    end

  end
  module HTML

    Markup[Date] = -> date,env=nil {
      {_: :a, class: :date,
       href: '/' + date[0..13].gsub(/[-T:]/,'/'), c: date}}

    Group['decades'] = -> graph {
      decades = {}
      graph.values.map{|resource|
        name = resource.R.parts[0] || ''
        decade = (name.match /^\d{4}$/) ? name[0..2]+'0s' : '/'
        decades[decade] ||= {name: decade, Contains => {}}
        decades[decade][Contains][resource.uri] = resource}
      decades}

  end
end
