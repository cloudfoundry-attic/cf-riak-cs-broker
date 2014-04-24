ENV['SETTINGS_PATH'] ||= File.expand_path('../../../settings.yml', __FILE__)

module RiakCsBroker
  class Config < Settingslogic

    source ENV['SETTINGS_PATH']
    load!

    def self.validate!
      # SettingsLogic throws an exception when a setting is accessed, but
      # has not been populated through the yml file.  So, we will just
      # access settings we want to validate and let SettingsLogic trow an exception
      # if a setting is not populated.

      self.riak_cs
      self.riak_cs.host
      self.riak_cs.port
      self.riak_cs.access_key_id
      self.riak_cs.secret_access_key

      self.ssl_validation
      self.username
      self.password
    end

    def self.catalog
      {
        "services" => [
          {
            "bindable" => true,
            "description" => "An S3-compatible open source storage built on top of Riak.",
            "id" => "33d2eeb0-0236-4c83-b494-da3faeb5b2e8",
            "metadata" => {
              "displayName" => "Riak CS Storage",
              "documentationUrl" => "https://github.com/cloudfoundry/cf-riak-cs-broker",
              "imageUrl" => "http://www.linux.com/news/galleries/image/riak-cs%3Fformat%3Dimage%26thumbnail%3Dsmall",
              "longDescription" => "Provisioning the service creates a Riak CS bucket. Binding an application creates unique credentials for that application to access the bucket.",
              "providerDisplayName" => "Riak CS",
              "supportUrl" => "https://github.com/cloudfoundry/cf-riak-cs-broker/issues"
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
                      "amount" => {"usd" => 0.0},
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
