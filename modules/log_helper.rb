module LogHelper

  # Shared logging function for standardized logging to the console
  def self.shared_log(controller, method, o)
    str = controller + '/' + method
    if not o.nil?
      str += ' - ' + o.to_s
    end
    puts str
  end

  def self.patch_controller_log(method, o)
    shared_log('PatchController', method, o)
  end

  def self.user_controller_log(method, o)
    shared_log('UserController', method, o)
  end

  def self.user_log(method, o)
    shared_log('User', method, o)
  end

end
