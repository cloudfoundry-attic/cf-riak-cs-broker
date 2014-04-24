require 'securerandom'
require 'spec_helper'

describe "Provisioning a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }

  def make_request(id = instance_id)
    put "/v2/service_instances/#{id}"
  end

  it "returns an Unauthorized HTTP response" do
    make_request
    last_response.status.should == 401
  end

  context "when authenticated", :authenticated do
    it "returns a 201 Created HTTP response with an empty JSON" do
      make_request
      last_response.status.should == 201
      last_response.body.should be_json_eql("{}")
    end

    context "and provisioning an existing instance" do
      it "returns a 409 Conflict HTTP response with an empty JSON" do
        make_request
        make_request
        last_response.status.should == 409
        last_response.body.should be_json_eql("{}")
      end
    end

    context "when there are errors when accessing Riak CS" do
      before do
        RiakCsBroker::ServiceInstances.any_instance.stub(:add).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
      end

      it_behaves_like "an endpoint that handles errors when accessing Riak CS"
    end
  end
end

describe "Deprovisioning a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }

  def make_request(id = instance_id)
    delete "/v2/service_instances/#{id}"
  end

  it "returns an 401 Unauthorized HTTP response" do
    make_request
    last_response.status.should == 401
  end

  context "when authenticated", :authenticated do
    context "when the instance exists" do
      before do
        create_instance
      end

      it "returns a 200 OK HTTP response with an empty JSON" do
        make_request
        last_response.status.should == 200
        last_response.body.should be_json_eql("{}")
      end

      context "and deprovisioning a non-empty instance" do
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:remove).and_raise(RiakCsBroker::ServiceInstances::InstanceNotEmptyError)
        end

        it "returns a 409 Conflict HTTP response with an error message" do
          make_request
          last_response.status.should == 409
          last_response.body.should be_json_eql({ description: "Could not unprovision because instance is not empty"}.to_json)
        end
      end
    end

    context "when the instance does not exist" do
      it "returns a 410 Not Found HTTP response with an empty JSON" do
        make_request
        last_response.status.should == 410
        last_response.body.should be_json_eql('{}')
      end
    end

    context "when there are errors when accessing Riak CS" do
      before do
        RiakCsBroker::ServiceInstances.any_instance.stub(:remove).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
      end

      it_behaves_like "an endpoint that handles errors when accessing Riak CS"
    end
  end
end
