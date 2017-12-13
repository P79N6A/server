class R

  def indexMail
    @verbose = true
    triples = 0
    triplrMail{|s,p,o|triples += 1}
    puts "    #{triples} triples"
  rescue Exception => e
    puts uri, e.class, e.message
  end

  def indexMails; glob.map &:indexMail end

end
