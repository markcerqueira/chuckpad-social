ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require './controllers/patch_controller'

Dir.glob('./{config,models,helpers,controllers}/*.rb').each { |file| require file }

class PatchControllerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    PatchController
  end

  def test_index
    get '/'
    assert last_response.ok?
  end

end