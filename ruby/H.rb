def H _
  case _
  when Hash then
    '<'+(_[:_]||:div).to_s+(_.keys-[:_,:c]).map{|a|
      ' '+a.to_s+'='+"'"+
      _[a].to_s.hsub({"'"=>'%27',
                       '>'=>'%3E',
                       '<'=>'%3C'})+"'"}.join+'>'+
      (_[:c] ? (H _[:c]) : '')+
      (_[:_] == :link ? '' : ('</'+(_[:_]||:div).to_s+'>'))
  when Array then
    _.map{|n|H n}.join
  else
    _.to_s
  end
end

class H

  def H.[] h; H h end

  def H.js a,inline=false
    p=a+'.js'
    inline ? {_: :script, c: p.E.r} :
    {_: :script, type: "text/javascript", src: p} end

  def H.once e,n,*h
    return if e[n]
    e[n]=true
    h end
end
