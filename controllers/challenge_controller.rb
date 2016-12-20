require './controllers/application_controller'

# ACME Challenge responder
# See: https://github.com/dmathieu/sabayon
class ChallengeController < ApplicationController

  get '/acme-challenge/:token' do
    data = []
    if ENV['ACME_KEY'] && ENV['ACME_TOKEN']
      data << { key: ENV['ACME_KEY'], token: ENV['ACME_TOKEN'] }
    else
      ENV.each do |k, v|
        if d = k.match(/^ACME_KEY_([0-9]+)/)
          index = d[1]
          data << { key: v, token: ENV["ACME_TOKEN_#{index}"] }
        end
      end
    end

    data.each do |e|
      if env['PATH_INFO'] == "/acme-challenge/#{e[:token]}"
        status 200
        content_type 'text/plain'
        body "#{e[:key]}"
        "#{e[:key]}"
        return
      end
    end

    status 500
    content_type 'text/plain'
    body 'No key found'
    'No key found'
  end

end
