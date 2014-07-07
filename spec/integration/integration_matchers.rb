def bucket_uri_from_response_body!(response_body, json_path)
  url = parse_json(response_body, json_path)
  URI.parse(url)
end

module BucketURIParsing
  include JsonSpec::Helpers

  def bucket_uri_from_response_body(response_body, json_path)
    bucket_uri_from_response_body!(response_body, json_path)
  rescue JsonSpec::MissingPath => e
    @bad_json_error = e
    nil
  rescue URI::BadURIError => e
    @bad_uri_error = e
    nil
  end

  def bucket_name_from_uri(uri)
    uri.path.sub(/^\//, '')
  end

  def fog_client_from_bucket_uri(bucket_uri)
    RiakCsIntegrationSpecHelper.fog_client(
      host:                  bucket_uri.hostname,
      port:                  bucket_uri.port,
      aws_access_key_id:     Addressable::URI.unencode_component(bucket_uri.user),
      aws_secret_access_key: Addressable::URI.unencode_component(bucket_uri.password)
    )
  end
end

RSpec::Matchers.define :be_a_bucket do
  match do |bucket_name|
    !RiakCsIntegrationSpecHelper.fog_client.directories.get(bucket_name).nil?
  end
end

RSpec::Matchers.define :include_a_writeable_bucket_uri_at do |json_path|
  include BucketURIParsing

  match do |binding_response|
    if (bucket_uri = bucket_uri_from_response_body(binding_response, json_path))
      fog_client  = fog_client_from_bucket_uri(bucket_uri)
      bucket_name = bucket_name_from_uri(bucket_uri)
      begin
        fog_client.put_object(bucket_name, "some-object", "some data")
      rescue Excon::Errors::Forbidden => e
        @writing_error = e
        false
      end
    end
  end

  failure_message do |binding_response|
    message = "expected #{binding_response} to contain a writeable bucket URI at #{json_path}"
    if @bad_json_error
      message << " but could not find the URL: #{@bad_json_error.message}"
    elsif @bad_uri_error
      message << " but could not parse the URI: #{@bad_uri_error.message}"
    elsif @writing_error
      message << " but could not write to the bucket: #{@writing_error.message}"
    end
    message
  end
end

RSpec::Matchers.define :include_a_readable_bucket_uri_at do |json_path|
  include BucketURIParsing

  match do |binding_response|
    if (bucket_uri = bucket_uri_from_response_body(binding_response, json_path))
      fog_client  = fog_client_from_bucket_uri(bucket_uri)
      bucket_name = bucket_name_from_uri(bucket_uri)
      begin
        fog_client.directories.get(bucket_name).files
      rescue Excon::Errors::Forbidden => e
        @reading_error = e
        false
      end
    end
  end

  failure_message do |binding_response|
    message = "expected #{binding_response} to contain a readable bucket URI at #{json_path}"
    if @bad_json_error
      message << " but could not find the URL: #{@bad_json_error.message}"
    elsif @bad_uri_error
      message << " but could not parse the URI: #{@bad_uri_error.message}"
    elsif @reading_error
      message << " but could not list the bucket: #{@reading_error.message}"
    end
    message
  end
end

class RemoveAccessToRiakCs
  include BucketURIParsing

  attr_reader :bucket_uri

  def initialize(bucket_uri)
    @bucket_uri = bucket_uri
  end

  def matches?(block)
    fog_client = fog_client_from_bucket_uri(bucket_uri)
    bucket_name = bucket_name_from_uri(bucket_uri)
    begin
      fog_client.put_object(bucket_name, "some-object", "some data")
    rescue Excon::Errors::Forbidden => e
      @writing_error = e
    end
    if @writing_error
      false
    else
      block.call
      begin
        fog_client.put_object(bucket_name, "some-other-object", "some data")
        false
      rescue Excon::Errors::Forbidden
        true
      end
    end
  end

  def failure_message
    message = "expected block to remove existing Riak CS access"
    message << " but never got access in the first place" if @writing_error
    message
  end
end

def remove_access_to_riak_cs(bucket_uri)
  RemoveAccessToRiakCs.new(bucket_uri)
end
