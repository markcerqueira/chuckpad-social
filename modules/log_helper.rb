module LogHelper

  # Shared logging function for standardized logging to the console
  def self.shared_log(controller, method, o)
    str = controller + '/' + method
    if not o.nil?
      str += ' - ' + o.to_s
    end
    puts str
  end

  def self.patch_log(method, o)
    shared_log('Patch', method, o)
  end

  def self.live_session_log(method, o)
    shared_log('LiveSession', method, o)
  end

  def self.live_controller_log(method, o)
    shared_log('LiveController', method, o)
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

  def self.digest_helper(method, o)
    shared_log('DigestHelper', method, o)
  end

  def self.analytics_helper(method, o)
    shared_log('AnalyticsHelper', method, o)
  end

  def self.mail_helper(method, o)
    shared_log('MailHelper', method, o)
  end

end
