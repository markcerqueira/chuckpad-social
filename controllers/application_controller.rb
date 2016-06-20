require 'sinatra'
require 'sinatra/flash'
require 'sinatra/base'

require 'active_record'
require 'json'

require './models/patch'
require './models/user'

class ApplicationController < Sinatra::Base

  # http://stackoverflow.com/a/13696534/265791
  # sets root as the parent-directory of the current file
  set :root, File.join(File.dirname(__FILE__), '..')

  # sets the view directory correctly
  set :views, Proc.new { File.join(root, "views") }

  # Register for Flash to work properly
  # TODO We should remove this at some point
  register Sinatra::Flash

  # Tell Sinatra about special MIME types
  # http://stackoverflow.com/a/18574464/265791
  configure do
    mime_type :ck, 'text/ck'
  end

  use Rack::Session::Cookie,
      :key => 'rack.session',
      :path => '/',
      :expire_after => 2592000, # 30 days in seconds
      :secret => (ENV['RACK_COOKIE_SECRET'] || 'ooY74TAY34UZqYguck4p').to_s

  # Shared logging function for standardized logging to the console
  def shared_log(controller, method, o)
    str = controller + '/' + method
    if not o.nil?
      str += ' - ' + o.to_s
    end
    puts str
  end

  # Main index page for app will route to the patches index page at erb :index
  get '/?' do
    redirect '/patch'
  end

  after do
    # Close the connection after the request is done so that we don't
    # deplete the ActiveRecord connection pool.
    ActiveRecord::Base.connection.close
  end

end