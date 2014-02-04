require 'fog'

module RiakCsIntegrationSpecHelper
  class << self
    def fog_client(options = {})
      Fog::Storage.new(fog_options.merge(riak_cs_credentials).merge(options))
    end

    private

    def fog_options
      {
        provider: 'AWS',
        path_style: true
      }
    end

    def riak_cs_credentials
      {
        host: ENV["RIAK_CS_HOST"],
        port: ENV["RIAK_CS_PORT"],
        scheme: ENV["RIAK_CS_SCHEME"] || 'http',
        aws_access_key_id: ENV["RIAK_CS_ACCESS_KEY_ID"],
        aws_secret_access_key: ENV["RIAK_CS_SECRET_ACCESS_KEY"]
      }
    end
  end
end