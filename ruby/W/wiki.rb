class E

  def triplrMarkdown
    require 'markdown'
    yield uri,Content,Markdown.new(r).to_html
  end

  def triplrOrg
    require 'org-ruby'
    r.do{|r|
      yield uri,Content,Orgmode::Parser.new(r).to_html}
  end

  def triplrTextile; require 'redcloth'
    yield uri,Content,RedCloth.new(r).to_html
  end

end
