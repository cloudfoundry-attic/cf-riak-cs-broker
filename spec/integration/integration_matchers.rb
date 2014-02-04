module BucketURIParsing
  def bucket_uri_from_response_body(response_body)
    response_hash = JSON.parse(response_body)
    URI.parse(response_hash['credentials']['uri'])
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

RSpec::Matchers.define :include_a_writeable_bucket_uri do
  include BucketURIParsing

  match do |binding_response|
    if (bucket_uri = bucket_uri_from_response_body(binding_response))
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

  failure_message_for_should do |binding_response|
    message = "expected #{binding_response} to contain a writeable bucket URI"
    if @bad_uri_error
      message << " but could not parse the URI: #{@bad_uri_error.message}"
    elsif @writing_error
      message << " but could not write to the bucket: #{@writing_error.message}"
    end
    message
  end
end

RSpec::Matchers.define :include_a_readable_bucket_uri do
  include BucketURIParsing

  match do |binding_response|
    if (bucket_uri = bucket_uri_from_response_body(binding_response))
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

  failure_message_for_should do |binding_response|
    message = "expected #{binding_response} to contain a readable bucket URI"
    if @bad_uri_error
      message << " but could not parse the URI: #{@bad_uri_error.message}"
    elsif @reading_error
      message << " but could not list the bucket: #{@reading_error.message}"
    end
    message
  end
end