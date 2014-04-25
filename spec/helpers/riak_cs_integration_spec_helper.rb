require 'fog'

module RiakCsIntegrationSpecHelper
  class << self
    def fog_client(options = {})
      Fog::Storage.new(fog_options.merge(riak_cs_credentials).merge(options))
    end

    def bucket_name(instance_id)
      RiakCsBroker::ServiceInstances.bucket_name(instance_id)
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
        host:                  RiakCsBroker::Config.riak_cs.host,
        port:                  RiakCsBroker::Config.riak_cs.port,
        scheme:                RiakCsBroker::Config.riak_cs.scheme,
        aws_access_key_id:     RiakCsBroker::Config.riak_cs.access_key_id,
        aws_secret_access_key: RiakCsBroker::Config.riak_cs.secret_access_key,
      }
    end
  end
end
