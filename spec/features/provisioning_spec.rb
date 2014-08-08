require 'securerandom'
require 'spec_helper'

describe "Provisioning a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }

  def make_request(id = instance_id)
    put "/v2/service_instances/#{id}"
  end

  it "returns an Unauthorized HTTP response" do
    make_request
    expect(last_response.status).to eq(401)
  end

  context "when authenticated", :authenticated do
    it "returns a 201 Created HTTP response with an empty JSON" do
      make_request
      expect(last_response.status).to eq(201)
      expect(last_response.body).to be_json_eql("{}")
    end

    context "and provisioning an existing instance" do
      it "returns a 409 Conflict HTTP response with an empty JSON" do
        make_request
        make_request
        expect(last_response.status).to eq(409)
        expect(last_response.body).to be_json_eql("{}")
      end
    end

    context "when there are errors when accessing Riak CS" do
      before do
        allow_any_instance_of(RiakCsBroker::ServiceInstances).to receive(:add).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
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
    expect(last_response.status).to eq(401)
  end

  context "when authenticated", :authenticated do
    context "when the instance exists" do
      before do
        create_instance
      end

      it "returns a 200 OK HTTP response with an empty JSON" do
        make_request
        expect(last_response.status).to eq(200)
        expect(last_response.body).to be_json_eql("{}")
      end
    end

    context "when the instance does not exist" do
      it "returns a 410 Not Found HTTP response with an empty JSON" do
        make_request
        expect(last_response.status).to eq(410)
        expect(last_response.body).to be_json_eql('{}')
      end
    end

    context "when there are errors when accessing Riak CS" do
      before do
        allow_any_instance_of(RiakCsBroker::ServiceInstances).to receive(:remove).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
      end

      it_behaves_like "an endpoint that handles errors when accessing Riak CS"
    end
  end
end
