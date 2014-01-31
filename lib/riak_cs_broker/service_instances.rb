require 'fog'

module RiakCsBroker
  class ServiceInstances
    class ClientError < StandardError
    end

    FOG_OPTIONS = {
      provider: 'AWS',
      path_style: true,
      scheme: 'https'
    }

    def initialize(options = {})
      @client = Fog::Storage.new({
                                           provider: FOG_OPTIONS[:provider],
                                           path_style: FOG_OPTIONS[:path_style],
                                           host: options[:host],
                                           port: options[:port],
                                           scheme: options[:scheme] || FOG_OPTIONS[:scheme],
                                           aws_access_key_id: options[:access_key_id],
                                           aws_secret_access_key: options[:secret_access_key]
                                         }
      )
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def add(instance_id)
      @client.directories.create(key: bucket_name(instance_id))
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def include?(instance_id)
      !@client.directories.get(bucket_name(instance_id)).nil?
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    private

    def bucket_name(id)
      "service-instance-#{id}"
    end
  end
end