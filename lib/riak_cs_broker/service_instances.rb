require 'addressable/template'
require 'fog'
require 'hash_to_acl_with_stripping'

module RiakCsBroker
  class ServiceInstances
    BINDING_BUCKET_NAME = 'cf-riak-cs-service-broker-bindings'

    class ClientError < StandardError
    end
    class InstanceNotFoundError < ClientError
    end
    class BindingAlreadyExistsError < ClientError
    end
    class BindingNotFoundError < ClientError
    end
    class ServiceUnavailableError < ClientError
    end

    FOG_OPTIONS = {
      provider:   'AWS',
      path_style: true,
      scheme:     'https'
    }

    attr_reader :storage_client, :provision_client

    def initialize(options = {})
      @storage_client   = Fog::Storage.new(
        provider:              FOG_OPTIONS[:provider],
        path_style:            FOG_OPTIONS[:path_style],
        host:                  options[:host],
        port:                  options[:port],
        scheme:                options[:scheme] || FOG_OPTIONS[:scheme],
        aws_access_key_id:     options[:access_key_id],
        aws_secret_access_key: options[:secret_access_key]
      )
      @provision_client = Fog::RiakCS::Provisioning.new(
        path_style:               FOG_OPTIONS[:path_style],
        host:                     options[:host],
        port:                     options[:port],
        scheme:                   options[:scheme] || FOG_OPTIONS[:scheme],
        riakcs_access_key_id:     options[:access_key_id],
        riakcs_secret_access_key: options[:secret_access_key]
      )
      @storage_client.directories.create(key: BINDING_BUCKET_NAME)
    rescue Excon::Errors::Timeout
      raise ServiceUnavailableError
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def add(instance_id)
      @storage_client.directories.create(key: self.class.bucket_name(instance_id))
    rescue Excon::Errors::Timeout
      raise ServiceUnavailableError
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def remove(instance_id)
      raise InstanceNotFoundError unless include?(instance_id)
      begin
        @storage_client.directories.get(self.class.bucket_name(instance_id)).files.all.each do |file|
          file.destroy
        end
        @storage_client.directories.destroy(self.class.bucket_name(instance_id))
      rescue Excon::Errors::Timeout
        raise ServiceUnavailableError
      rescue => e
        raise ClientError.new("#{e.class}: #{e.message}")
      end
    end

    def include?(instance_id)
      !@storage_client.directories.get(self.class.bucket_name(instance_id)).nil?
    rescue Excon::Errors::Timeout
      raise ServiceUnavailableError
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def bind(instance_id, binding_id)
      raise InstanceNotFoundError unless include?(instance_id)
      raise BindingAlreadyExistsError.new("Binding for #{binding_id} already exists.") if bound?(binding_id)

      begin
        user_id, user_key, user_secret = create_user(binding_id)
        add_user_to_bucket_acl(self.class.bucket_name(instance_id), user_id)

        {
          uri:               bucket_uri(instance_id, user_key, user_secret),
          access_key_id:     user_key,
          secret_access_key: user_secret
        }
      rescue Fog::RiakCS::Provisioning::UserAlreadyExists => e
        raise BindingAlreadyExistsError.new("Attempted to create a Riak CS user for #{binding_id}, but couldn't: #{e.message}.")
      rescue Fog::RiakCS::Provisioning::ServiceUnavailable => e
        raise ServiceUnavailableError.new("Riak CS unavailable: #{e.message}")
      rescue Excon::Errors::Timeout
        raise ServiceUnavailableError
      rescue => e
        raise ClientError.new("#{e.class}: #{e.message}")
      end
    end

    def bound?(binding_id)
      user_id_from_binding_id(binding_id)
    rescue Excon::Errors::Timeout
      raise ServiceUnavailableError
    end

    def unbind(instance_id, binding_id)
      raise InstanceNotFoundError unless include?(instance_id)
      raise BindingNotFoundError unless bound?(binding_id)

      begin
        user_id = user_id_from_binding_id(binding_id)
        delete_user_from_bucket_acl(self.class.bucket_name(instance_id), user_id)
        delete_binding_id_to_user_id_mapping(binding_id)
      rescue Excon::Errors::Timeout
        raise ServiceUnavailableError
      rescue => e
        raise ClientError.new("#{e.class}: #{e.message}")
      end
    end

    def self.bucket_name(bucket_id)
      "service-instance-#{bucket_id}"
    end

    private

    def user_id_from_binding_id(binding_id)
      file = @storage_client.directories.get(BINDING_BUCKET_NAME).files.get(binding_id)
      file.body if file
    end

    def bucket_uri(bucket_id, user_key, user_secret)
      request_uri         = Addressable::URI.parse(@storage_client.request_url(bucket_name: self.class.bucket_name(bucket_id)))
      bucket_uri_template = Addressable::Template.new("{scheme}://{key}:{secret}@{host}:{port}{/bucket_name}")
      bucket_uri_template.expand(
        scheme:      request_uri.scheme,
        key:         user_key,
        secret:      user_secret,
        host:        request_uri.host,
        port:        request_uri.port,
        bucket_name: self.class.bucket_name(bucket_id)
      ).to_s
    end

    def create_user(user_name)
      user = @provision_client.create_user("#{user_name}@example.com", user_name).body

      store_binding_id_to_user_id_mapping(user_name, user['id'])

      [user['id'], user['key_id'], user['key_secret']]
    end

    def store_binding_id_to_user_id_mapping(binding_id, user_id)
      @storage_client.put_object(BINDING_BUCKET_NAME, binding_id, user_id)
    end

    def delete_binding_id_to_user_id_mapping(binding_id)
      @storage_client.delete_object(BINDING_BUCKET_NAME, binding_id)
    end

    def add_user_to_bucket_acl(bucket_name, user_id)
      grantee_hash             = { 'ID' => user_id }
      write_grant              = { 'Permission' => 'WRITE', 'Grantee' => grantee_hash }
      read_grant               = { 'Permission' => 'READ', 'Grantee' => grantee_hash }
      acl                      = @storage_client.get_bucket_acl(bucket_name).body
      acl['AccessControlList'] += [read_grant, write_grant]
      @storage_client.put_bucket_acl(bucket_name, acl)
    end

    def delete_user_from_bucket_acl(bucket_name, user_id)
      acl = @storage_client.get_bucket_acl(bucket_name).body
      acl['AccessControlList'].reject! { |item| item["Grantee"]["ID"] == user_id }
      @storage_client.put_bucket_acl(bucket_name, acl)
    end
  end
end
