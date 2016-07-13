require 'sinatra'
require 'sinatra/base'

require 'active_record'
require 'bcrypt'
require 'email_validator'
require 'json'
require 'mail'
require 'strong_password'

require './models/patch'
require './models/user'

module MailHelper

  # Helper method to send someone an email
  def self.send_email(to_field, subject_text, html_body_text)
    begin
      mail = Mail.new do
        to to_field
        from ENV['EMAIL_FROM_EMAIL'].to_s
        subject subject_text
        # body body_text
        html_part do
          content_type 'text/html; charset=UTF-8'
          body html_body_text
        end
      end
      mail.deliver!
    rescue
      puts 'send_email - error sending email: ' + "#{$!}"
    end
  end

end

class ApplicationController < Sinatra::Base

  CHUCKPAD_SOCIAL_IOS = 'chuckpad-social-ios'

  helpers MailHelper

  # Configure mail gem
  options = { :address              => ENV['EMAIL_MAIL_SERVER'].to_s,
              :port                 => 587,
              :user_name            => ENV['EMAIL_USER_NAME'].to_s,
              :password             => ENV['EMAIL_PASSWORD'].to_s,
              :authentication       => 'plain',
              :enable_starttls_auto => true,
              :openssl_verify_mode  => OpenSSL::SSL::VERIFY_NONE }

  Mail.defaults do
    delivery_method :smtp, options
  end

  # Tell Sinatra about special MIME types
  # http://stackoverflow.com/a/18574464/265791
  configure do
    mime_type :ck, 'text/ck'
  end

  # http://stackoverflow.com/a/13696534/265791
  # sets root as the parent-directory of the current file
  set :root, File.join(File.dirname(__FILE__), '..')

  # sets the view directory correctly
  set :views, Proc.new { File.join(root, 'views') }

  # Configure Rack session cookies which is used by the web to persist a
  # session across various routes
  use Rack::Session::Cookie,
      :key => 'rack.session',
      :path => '/',
      :expire_after => 2592000, # 30 days in seconds
      :secret => ENV['RACK_COOKIE_SECRET'].to_s

  # Shared logging function for standardized logging to the console
  def shared_log(controller, method, o)
    str = controller + '/' + method
    if not o.nil?
      str += ' - ' + o.to_s
    end
    puts str
  end

  # Returns true if the request is being made from a "native" (e.g. iOS) client
  def from_native_client(request)
    return request.user_agent.include? CHUCKPAD_SOCIAL_IOS
  end

  def fail_with_json_msg(code, msg)
    # We want the HTTP request to succeed so set it to 200
    # Code internally will be non-200 in this case
    status 200
    content_type 'application/json'
    body get_response_body(code, msg)
  end

  def success_with_json_msg(msg)
    status 200
    content_type 'application/json'
    body get_response_body(200, msg)
  end

  def get_response_body(code, msg)
    {
        'code' => code,
        'message' => msg
    }.to_json
  end

  # Redirects to target page setting status message to passed msg
  def redirect_with_status_message(msg, target)
    session[:status] = msg
    redirect target
  end

  # Main index page for app will route to the patches index page at erb :index
  get '/?' do
    redirect '/patch'
  end

  # A certain reviewer of an app that may be using this API may not like it if the app could download and execute code.
  # If this API does not return true, clients should NOT attempt to make any other API requests.
  get '/enabled/?' do
    # Update this to include all versions of the app that are released but NOT in review!
    supported_lib_versions = ['0.1']

    if from_native_client(request)
      enabled = supported_lib_versions.include? params[:version]
    else
      enabled = true
    end

    enabled ? success_with_json_msg('') : fail_with_json_msg(500, '')
  end

  after do
    # Close the connection after the request is done so that we don't deplete the ActiveRecord connection pool.
    ActiveRecord::Base.connection.close
  end

end