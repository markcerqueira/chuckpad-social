require 'sinatra'
require 'sinatra/base'

require 'active_record'
require 'bcrypt'
require 'better_errors'
require 'digest'
require 'email_validator'
require 'json'
require 'staccato'
require 'sendgrid-ruby'
require 'strong_password'

require './extensions/string_extension'
require './extensions/vash'

require './models/abuse_report'
require './models/auth_token'
require './models/patch'
require './models/patch_resource'
require './models/user'

require './modules/analytics_helper'
require './modules/digest_helper'
require './modules/log_helper'
require './modules/mail_helper'
require './modules/response_helper'
require './modules/request_helper'

require './errors/auth_token_invalid_error'
require './errors/digest_error'
require './errors/patch_create_error'
require './errors/patch_not_found_error'
require './errors/patch_permission_error'
require './errors/patch_update_error'
require './errors/user_create_error'
require './errors/user_not_found_error'

class ApplicationController < Sinatra::Base

  # Tell Sinatra about special MIME types
  # http://stackoverflow.com/a/18574464/265791
  configure do
    mime_type :ck, 'text/ck'
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
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

  def respond(code, msg)
    # Even for errors we want the HTTP request to succeed so set it this status to 200. If there are other errors we
    # will set them internally in the JSON.
    status 200
    content_type 'text/json'

    response_body = {
        'code' => code,
        'message' => msg
    }.to_json

    body response_body
  end

  # Resource errors should 404 directly
  def respond_resource_error()
    status 404
  end

  # Redirects to target page setting status message to passed msg
  def redirect_to_index_with_status_msg(controller, msg)
    session[:status] = msg
    if controller.is_a?(UserController)
      redirect '/user'
    else
      redirect '/patch'
    end
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