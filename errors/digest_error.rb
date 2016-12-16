class DigestError < StandardError

  def initialize(msg='Request is malformed. Please try again.')
    super
  end

end
