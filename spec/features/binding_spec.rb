require 'securerandom'
require 'spec_helper'

describe "Binding a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }
  let(:binding_id) { SecureRandom.uuid }

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
          it "returns a 201 Created HTTP response" do
            make_request
            last_response.status.should == 201
          end

          it "returns a JSON object containing credentials" do
            make_request
            last_response.body.should have_json_path('credentials/uri')
            last_response.body.should have_json_path('credentials/access_key_id')
            last_response.body.should have_json_path('credentials/secret_access_key')
          end
        end

        context "when binding is unsuccessful because the service is unavailable" do
          before do
            RiakCsBroker::ServiceInstances.any_instance.stub(:bind).and_raise(RiakCsBroker::ServiceInstances::ServiceUnavailableError)
          end

          it "returns 503 Service Not Available with an error message" do
            make_request
            expect(last_response.status).to eq(503)
            last_response.body.should be_json_eql({ description: "Could not bind because service is unavailable" }.to_json)
          end
        end
      end

      context "when it is already bound" do
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:bound?).and_return(true)
        end

        it "returns a 409 Conflict HTTP response with an empty JSON" do
          make_request
          last_response.status.should == 409
          last_response.body.should be_json_eql("{}")
        end
      end

      context "when there are errors when accessing Riak CS" do
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:bind).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
        end

        it_behaves_like "an endpoint that handles errors when accessing Riak CS"
      end
    end

    context "when the service instance does not exist" do
      it "returns 404 Not Found with an error message" do
        make_request
        last_response.status.should == 404
        last_response.body.should be_json_eql({ description: "Could not bind to an unknown service instance: #{instance_id}" }.to_json)
      end

    end
  end
end

describe "Unbinding a Riak CS service instance" do
  let(:instance_id) { SecureRandom.uuid }
  let(:binding_id) { SecureRandom.uuid }

  def make_request(id = instance_id, b_id = binding_id)
    delete "/v2/service_instances/#{id}/service_bindings/#{b_id}"
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
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:unbind).and_raise(RiakCsBroker::ServiceInstances::BindingNotFoundError)
        end

        it "returns 410 Not Found with an empty JSON" do
          make_request
          expect(last_response.status).to eq(410)
          expect(last_response.body).to be_json_eql('{}')
        end
      end

      context "when it is bound" do
        before do
          RiakCsBroker::ServiceInstances.any_instance.stub(:unbind)
        end

        it "returns 200 OK with with an empty JSON" do
          make_request
          expect(last_response.status).to eq(200)
          expect(last_response.body).to be_json_eql('{}')
        end

        context "when binding is unsuccessful because the service is unavailable" do
          before do
            RiakCsBroker::ServiceInstances.any_instance.stub(:unbind).and_raise(RiakCsBroker::ServiceInstances::ServiceUnavailableError)
          end

          it "returns 503 Service Not Available with an error message" do
            make_request
            expect(last_response.status).to eq(503)
            last_response.body.should be_json_eql({ description: "Could not bind because service is unavailable" }.to_json)
          end
        end

        context "when there are errors when accessing Riak CS" do
          before do
            RiakCsBroker::ServiceInstances.any_instance.stub(:unbind).and_raise(RiakCsBroker::ServiceInstances::ClientError.new("some-error-message"))
          end

          it_behaves_like "an endpoint that handles errors when accessing Riak CS"
        end
      end
    end

    context "when the service instance does not exist" do
      it "returns 410 Not Found with an empty JSON" do
        make_request
        expect(last_response.status).to eq(410)
        expect(last_response.body).to be_json_eql('{}')
      end
    end
  end
end
