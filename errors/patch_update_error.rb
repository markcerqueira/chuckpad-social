class PatchUpdateError < StandardError

  def initialize(msg='There was an error updating your patch. Please try again.')
    super
  end

end
