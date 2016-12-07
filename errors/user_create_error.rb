class UserCreateError < StandardError

  def initialize(msg='There was an error creating your user. Please try again.')
    super
  end

end
