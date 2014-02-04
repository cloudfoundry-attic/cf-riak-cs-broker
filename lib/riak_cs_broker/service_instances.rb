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
    class BindingAlreadyExists < ClientError
    end
    class ServiceUnavailable < ClientError
    end

    FOG_OPTIONS = {
      provider: 'AWS',
      path_style: true,
      scheme: 'https'
    }

    attr_reader :storage_client

    def initialize(options = {})
      @storage_client = Fog::Storage.new(
        provider: FOG_OPTIONS[:provider],
        path_style: FOG_OPTIONS[:path_style],
        host: options[:host],
        port: options[:port],
        scheme: options[:scheme] || FOG_OPTIONS[:scheme],
        aws_access_key_id: options[:access_key_id],
        aws_secret_access_key: options[:secret_access_key]
      )
      @provision_client = Fog::RiakCS::Provisioning.new(
        path_style: FOG_OPTIONS[:path_style],
        host: options[:host],
        port: options[:port],
        scheme: options[:scheme] || FOG_OPTIONS[:scheme],
        riakcs_access_key_id: options[:access_key_id],
        riakcs_secret_access_key: options[:secret_access_key]
      )
      @storage_client.put_bucket(BINDING_BUCKET_NAME)
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def add(instance_id)
      @storage_client.directories.create(key: bucket_name(instance_id))
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def include?(instance_id)
      !@storage_client.directories.get(bucket_name(instance_id)).nil?
    rescue => e
      raise ClientError.new("#{e.class}: #{e.message}")
    end

    def bind(instance_id, binding_id)
      raise InstanceNotFoundError unless include?(instance_id)
      raise BindingAlreadyExists.new("Binding for #{binding_id} already exists.") if bound?(binding_id)

      user_id, user_key, user_secret = create_user(binding_id)
      add_user_to_bucket_acl(bucket_name(instance_id), user_id)

      {
        uri: bucket_uri(instance_id, user_key, user_secret),
        access_key_id: user_key,
        secret_access_key: user_secret
      }
    rescue Fog::RiakCS::Provisioning::UserAlreadyExists => e
      raise BindingAlreadyExists.new("Attempted to create a Riak CS user for #{binding_id}, but couldn't: #{e.message}.")
    rescue Fog::RiakCS::Provisioning::ServiceUnavailable => e
      raise ServiceUnavailable.new("Riak CS unavailable: #{e.message}")
    end

    def bound?(binding_id)
      @storage_client.get_object(BINDING_BUCKET_NAME, binding_id)
    rescue Excon::Errors::NotFound
      return false
    end

    private

    def bucket_name(bucket_id)
      "service-instance-#{bucket_id}"
    end

    def bucket_uri(bucket_id, user_key, user_secret)
      request_uri = Addressable::URI.parse(@storage_client.request_url(bucket_name: bucket_name(bucket_id)))
      bucket_uri_template = Addressable::Template.new("{scheme}://{key}:{secret}@{host}:{port}{/bucket_name}")
      bucket_uri_template.expand(
        scheme: request_uri.scheme,
        key: user_key,
        secret: user_secret,
        host: request_uri.host,
        port: request_uri.port,
        bucket_name: bucket_name(bucket_id)
      ).to_s
    end

    def create_user(user_name)
      user_response = @provision_client.create_user("#{user_name}@example.com", user_name).body

      @storage_client.put_object(BINDING_BUCKET_NAME, user_name, user_response['key_id'])

      [user_response['id'], user_response['key_id'], user_response['key_secret']]
    end

    def add_user_to_bucket_acl(bucket_name, user_id)
      grantee_hash = { 'ID' => user_id }
      write_grant  = { 'Permission' => 'WRITE', 'Grantee' => grantee_hash }
      read_grant   = { 'Permission' => 'READ', 'Grantee' => grantee_hash }
      acl          = @storage_client.get_bucket_acl(bucket_name).body
      acl['AccessControlList'] += [read_grant, write_grant]
      @storage_client.put_bucket_acl(bucket_name, acl)
    end
  end
end