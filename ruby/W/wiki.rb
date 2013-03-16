class E

  def markdown; require 'markdown'
    yield uri,Content,Markdown.new(r).to_html
  end

  def org; require 'org-ruby'
    r.do{|r|
      yield uri,Content,Orgmode::Parser.new(r).to_html}
  end

  def textile; require 'redcloth'
    yield uri,Content,RedCloth.new(r).to_html
  end

end
