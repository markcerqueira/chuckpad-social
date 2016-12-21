class PatchNotFoundError < StandardError

  def initialize(msg='That patch could not be found. Please try again.')
    super
  end

end
