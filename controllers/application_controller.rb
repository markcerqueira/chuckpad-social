require 'sinatra'
require 'sinatra/base'

require 'active_record'
require 'bcrypt'
require 'email_validator'
require 'json'
require 'sendgrid-ruby'
require 'strong_password'

require './models/abuse_report'
require './models/auth_token'
require './models/patch'
require './models/user'

require './modules/log_helper'
require './modules/mail_helper'

class ApplicationController < Sinatra::Base

  CHUCKPAD_SOCIAL_IOS = 'chuckpad-social-ios'

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

  # Returns true if the request is being made from a "native" (e.g. iOS) client
  def from_native_client(request)
    return request.user_agent.include? CHUCKPAD_SOCIAL_IOS
  end

  def fail_with_json_msg(code, msg)
    # We want the HTTP request to succeed so set it to 200
    # Code internally will be non-200 in this case
    status 200
    content_type 'text/json'
    body get_response_body(code, msg)
  end

  def success_with_json_msg(msg)
    status 200
    content_type 'text/json'
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

  after do
    # Close the connection after the request is done so that we don't deplete the ActiveRecord connection pool.
    ActiveRecord::Base.connection.close
  end

end