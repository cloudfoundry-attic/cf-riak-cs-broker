require 'securerandom'
require 'spec_helper'

describe "Binding a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }
  let(:binding_id) { SecureRandom.uuid }

  def create_instance(id = instance_id)
    put "/v2/service_instances/#{id}"
  end

  def make_request(id = instance_id, b_id = binding_id)
    put "/v2/service_instances/#{id}/service_bindings/#{b_id}"
  end

  it "returns an Unauthorized HTTP response" do
    make_request
    last_response.status.should == 401
  end

  context "when authenticated", :authenticated do
    context "when the service instance exists" do
      before do
        create_instance
      end

      context "when it is not bound" do
        context "when binding is successful" do
          it "returns a Created HTTP response" do
            make_request
            last_response.status.should == 201
          end

          it "returns a JSON object containing credentials" do
            make_request
            last_response.body.should have_json_path('credentials/uri')
          end
        end

        context "when binding is unsuccessful because the service is unavailable" do
          before do
            RiakCsBroker::ServiceInstances.any_instance.stub(:bind).and_raise(RiakCsBroker::ServiceInstances::ServiceUnavailable)
          end

          it "returns service not available" do
            make_request
            expect(last_response.status).to eq(503)
          end
        end
      end

      context "when it is already bound" do
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:bound?).and_return(true)
        end

        it "returns a Conflict HTTP response" do
          make_request
          last_response.status.should == 409
        end
      end
    end

    context "when the service instance does not exist" do
      it "returns Not Found" do
        make_request
        last_response.status.should == 404
      end
    end
  end
end
