require 'webmock'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
WebMock.disable_net_connect!(allow: 'codeclimate.com')


ENV["RACK_ENV"] = "test"

require File.expand_path('../../lib/riak_cs_broker/app', __FILE__)

RiakCsBroker::App.set :logger, Logger.new("/dev/null")

Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each { |file| require file }

module RiakCsBrokerApp
  def app
    @app ||= RiakCsBroker::App.new
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include JsonSpec::Helpers
  config.include RequestSpecHelpers
  config.include RiakCsBrokerApp

  config.treat_symbols_as_metadata_keys_with_true_values = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:each, :authenticated) do
    authorize RiakCsBroker::Config.username, RiakCsBroker::Config.password
  end

  config.before(:each) do |c|
    if example.metadata[:integration].nil?
      Fog.mock!
      Fog::Mock.reset
    end
  end
end
