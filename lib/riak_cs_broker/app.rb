require 'json'

require 'bundler/setup'
ENV["RACK_ENV"] ||= "development"
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

$:.unshift(File.expand_path('../../', __FILE__))
require 'riak_cs_broker/config'

module RiakCsBroker
  class App < Sinatra::Base
    use Rack::Auth::Basic, "Cloud Foundry Riak CS Service Broker" do |username, password|
      [username, password] == [Config["basic_auth"]["username"], Config["basic_auth"]["password"]]
    end

    before do
      content_type "application/json"
    end

    get '/v2/catalog' do
      RiakCsBroker::Config['catalog'].to_json
    end
  end
end