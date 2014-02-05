ENV["RACK_ENV"] = "test"

require 'securerandom'
require 'webmock'

require 'spec_helper'
require_relative 'integration_matchers'

# load the real credentials
Dotenv.overload '.env'

WebMock.after_request { |request_signature, response| $webmock_request = request_signature; $webmock_response = response }
WebMock.allow_net_connect!

describe "Integration with a Riak CS cluster" do
  let(:instance_id) { SecureRandom.uuid }

  describe "provisioning" do
    it "creates a bucket in Riak CS", :authenticated, :integration do
      put "/v2/service_instances/#{instance_id}"

      expect(RiakCsIntegrationSpecHelper.bucket_name(instance_id)).to be_a_bucket
    end
  end

  describe "binding" do
    let(:binding_id) { SecureRandom.uuid }

    it "creates a user in Riak CS that can read and write the bucket", :authenticated, :integration do
      put "/v2/service_instances/#{instance_id}"
      put "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"

      binding_response = last_response.body
      expect(binding_response).to include_a_writeable_bucket_uri_at('credentials/uri')
      expect(binding_response).to include_a_readable_bucket_uri_at('credentials/uri')
    end
  end

  describe "unbinding" do
    let(:binding_id) { SecureRandom.uuid }

    it "removes the user's access to the Riak CS bucket", :authenticated, :integration do
      put "/v2/service_instances/#{instance_id}"
      put "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"

      bucket_uri = bucket_uri_from_response_body!(last_response.body, 'credentials/uri')

      expect {
        delete "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"
      }.to remove_access_to_riak_cs(bucket_uri)
    end
  end

  describe "deprovisioning" do
    it "deletes an empty bucket in Riak CS", :authenticated, :integration do
      put "/v2/service_instances/#{instance_id}"
      delete "/v2/service_instances/#{instance_id}"

      expect(RiakCsIntegrationSpecHelper.bucket_name(instance_id)).not_to be_a_bucket
    end
  end
end
