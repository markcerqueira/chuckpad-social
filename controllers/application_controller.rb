require 'sinatra'
require 'active_record'

class ApplicationController < Sinatra::Base

  # http://stackoverflow.com/a/13696534/265791
  # sets root as the parent-directory of the current file
  set :root, File.join(File.dirname(__FILE__), '..')

  # sets the view directory correctly
  set :views, Proc.new { File.join(root, "views") }

  # Tell Sinatra about special MIME types
  # http://stackoverflow.com/a/18574464/265791
  configure do
    mime_type :ck, 'text/ck'
  end

  get '/?' do
    @patches = Patch.all
    erb :index
  end

  after do
    # Close the connection after the request is done so that we don't
    # deplete the ActiveRecord connection pool.
    ActiveRecord::Base.connection.close
  end

end