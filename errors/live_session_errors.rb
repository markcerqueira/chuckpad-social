class LiveSessionCreateError < StandardError

  def initialize(msg='There was an error creating your live session. Please try again.')
    super
  end

end

class LiveSessionNotFoundError < StandardError

  def initialize(msg='No live session could be found with that identifier. Please try again.')
    super
  end

end

class LiveSessionPermissionError < StandardError

  def initialize(msg='You do not have permissions to modify this live session. Please try again.')
    super
  end

end
