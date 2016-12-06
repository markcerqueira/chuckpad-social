class PatchCreateError < StandardError

  def initialize(msg='There was an error creating your patch. Please try again.')
    super
  end

end
