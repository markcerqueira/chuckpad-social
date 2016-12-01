class String
  def matches?(regex)
    !(self =~ regex).nil?
  end
end
