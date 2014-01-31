require 'json'
require 'dotenv'

require 'bundler/setup'
ENV["RACK_ENV"] ||= "development"
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

$:.unshift(File.expand_path('../../', __FILE__))
require 'riak_cs_broker/config'
require 'riak_cs_broker/service_instances'

Dotenv.load

module RiakCsBroker
  class App < Sinatra::Base
    use Rack::Auth::Basic, "Cloud Foundry Riak CS Service Broker" do |username, password|
      [username, password] == [Config.basic_auth[:username], Config.basic_auth[:password]]
    end

    before do
      content_type "application/json"
    end

    get '/v2/catalog' do
      RiakCsBroker::Config.catalog.to_json
    end

    put '/v2/service_instances/:id' do
      begin
        if instances.include?(params[:id])
          status 409
        else
          instances.add(params[:id])
          status 201
        end
        "{}"
      rescue RiakCsBroker::ServiceInstances::ClientError, RiakCsBroker::Config::ConfigError => e
        status 500
        {description: e.message}.to_json
      end
    end

    private

    def instances
        @@instances ||= ServiceInstances.new(Config.riak_cs)
    end
  end
end