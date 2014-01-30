require 'securerandom'
require 'spec_helper'

describe "Integration with a Riak CS cluster" do
  describe "provisioning" do
    let(:instance_id) { SecureRandom.uuid }

    def make_request(id)
      put "/v2/service_instances/#{id}"
    end

    it "creates a bucket in Riak CS", :authenticated, :integration do
      make_request(instance_id)

      expect(RiakCsIntegrationSpecHelper.bucket_exists?("service-instance-#{instance_id}")).to be_true
    end
  end
end
