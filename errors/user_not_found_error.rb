class UserNotFoundError < StandardError

  def initialize(msg='That user cannot be found. Please try again.')
    super
  end

end
