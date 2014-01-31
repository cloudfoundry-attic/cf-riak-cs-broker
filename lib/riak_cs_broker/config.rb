module RiakCsBroker
  module Config
    class ConfigError < StandardError
    end

    def self.basic_auth
      {
        username: ENV['RIAK_CS_BROKER_USERNAME'],
        password: ENV['RIAK_CS_BROKER_PASSWORD']
      }
    end

    def self.riak_cs
      riak_config = {
        host: ENV['RIAK_CS_HOST'],
        port: ENV['RIAK_CS_PORT'],
        scheme: ENV['RIAK_CS_SCHEME'],
        access_key_id: ENV['RIAK_CS_ACCESS_KEY_ID'],
        secret_access_key: ENV['RIAK_CS_SECRET_ACCESS_KEY'],
      }
      if riak_config.values_at(:host, :port, :access_key_id, :secret_access_key).include?(nil)
        raise ConfigError.new("Riak CS is not configured.")
      end
      riak_config
    end

    def self.catalog
      {
        "services" => [
          {
            "bindable" => "true",
            "description" => "An S3-compatible open source storage built on top of Riak.",
            "id" => "33d2eeb0-0236-4c83-b494-da3faeb5b2e8",
            "metadata" => {
              "displayName" => "Riak CS Storage",
              "documentationUrl" => "https://github.com/cf-blobstore-eng/cf-riak-cs-service-broker",
              "imageUrl" => "http://www.linux.com/news/galleries/image/riak-cs%3Fformat%3Dimage%26thumbnail%3Dsmall",
              "longDescription" => "Provisioning the service creates a Riak CS bucket. Binding an application creates unique credentials for that application to access the bucket.",
              "providerDisplayName" => "Riak CS",
              "supportUrl" => "https://github.com/cf-blobstore-eng/cf-riak-cs-service-broker/issues"
            },
            "name" => "riak-cs",
            "plans" => [
              {
                "description" => "A bucket on Riak CS.",
                "id" => "946ce484-376b-41b4-8c4e-4bc830676115",
                "metadata" => {
                  "bullets" => ["Buckets are private"],
                  "costs" => [
                    {
                      "amount" => {"usd" => "0.0"},
                      "unit" => "MONTHLY"
                    }
                  ],
                  "displayName" => "Bucket"
                },
                "name" => "bucket"
              }
            ],
            "tags" => ["blobstore"]
          }
        ]
      }
    end
  end
end