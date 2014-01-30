require 'securerandom'
require 'spec_helper'

describe "Provisioning a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }

  def make_request(id = instance_id)
    put "/v2/service_instances/#{id}"
  end

  before(:each) do
    make_request
  end

  it "returns an Unauthorized HTTP response" do
    last_response.status.should == 401
  end

  context "when authenticated", :authenticated do
    it "returns a Created HTTP response" do
      last_response.status.should == 201
    end

    it "returns an empty JSON object" do
      last_response.body.should be_json_eql("{}")
    end

    context "and provisioning an existing instance" do
      it "returns a Conflict HTTP response" do
        make_request
        last_response.status.should == 409
      end
    end
  end
end