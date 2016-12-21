class PatchPermissionError < StandardError

  def initialize(msg='You do not have permissions to modify this patch. Please try again.')
    super
  end

end
