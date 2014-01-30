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
      @client = Fog::Storage.new(FOG_OPTIONS.merge(options))
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