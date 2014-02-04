require 'spec_helper'

RSpec::Matchers.define :have_grant_for do |expected_user_key|
  match do |acl|
    grants = acl['AccessControlList']
    if @permission
      grants.find { |grant| grant['Grantee']['ID'] == expected_user_key && grant['Permission'] == @permission }
    else
      grants.find { |grant| grant['Grantee']['ID'] == expected_user_key }
    end
  end

  chain :with_permission do |permission|
    @permission = permission
  end

  failure_message_for_should do |acl|
    message = "expected a grant with Grantee ID #{expected_user_key}"
    message << " and Permission #{@permission}" if @permission
    message << " to be in #{acl.inspect}"
    message
  end

  failure_message_for_should_not do |acl|
    message = "expected a grant with Grantee ID #{expected_user_key}"
    message << " and Permission #{@permission}" if @permission
    message << " not to be in #{acl.inspect}"
    message
  end
end

describe RiakCsBroker::ServiceInstances do
  class MyError < StandardError
  end

  let(:service_instances) { described_class.new(RiakCsBroker::Config.riak_cs) }

  describe "#initialize" do
    it "raises a ClientError if the client fails to initialize" do
      Fog::Storage.stub(:new).and_raise(MyError.new("some-error-message"))

      expect { service_instances }.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
    end
  end

  describe "#add" do
    it "stores requested service instances" do
      service_instances.add("my-instance")
      expect(service_instances.include?("my-instance")).to be_true
    end

    it "raises a ClientError if the client fails to create a bucket" do
      storage = double(:storage).as_null_object
      storage.stub_chain(:directories, :create).and_raise(MyError.new("some-error-message"))

      Fog::Storage.stub(:new).and_return(storage)

      expect { service_instances.add("my-instance") }.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
    end
  end

  describe "#include?" do
    it "does not include any instances that were never created" do
      expect(service_instances.include?("never-created")).to be_false
    end

    it "raises a ClientError if the client fails to look up a bucket" do
      storage = double(:storage).as_null_object
      storage.stub_chain(:directories, :get).and_raise(MyError.new("some-error-message"))

      Fog::Storage.stub(:new).and_return(storage)

      expect { service_instances.include?("my-instance") }.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
    end
  end

  describe "#bind" do
    context "when the instance does not exist" do
      it "raises an error" do
        expect { service_instances.bind("nonexistent-instance", "new-binding-id") }.
          to raise_error(RiakCsBroker::ServiceInstances::InstanceNotFoundError)
      end
    end

    context "when the instance exists" do
      let(:expected_creds) { {
        uri: "https://user-key:user-secret@myhost.com:8080/service-instance-my-instance"
      } }

      before do
        service_instances.add("my-instance")
      end

      context "and the binding id is not already bound" do
        before do
          response = double(:response, body: {
            'key_id' => 'user-key',
            'key_secret' => 'user-secret',
            'id' => 'user-id'
          })
          Fog::RiakCS::Provisioning::Mock.any_instance.stub(:create_user).and_return(response)
        end

        it "creates a user and returns credentials" do
          expect(service_instances.bind("my-instance", "some-binding-id")).to eq(expected_creds)
        end

        it "adds the user to the bucket ACL" do
          service_instances.bind("my-instance", "some-binding-id")
          acl = service_instances.storage_client.get_bucket_acl("service-instance-my-instance").body
          expect(acl).to have_grant_for("user-id").with_permission("READ")
          expect(acl).to have_grant_for("user-id").with_permission("WRITE")
        end
      end

      context "and the binding id has already been bound" do
        before do
          service_instances.add("some-other-instance")
          service_instances.bind("some-other-instance", "original-binding-id")
        end

        it "should raise an error" do
          expect { service_instances.bind("my-instance", "original-binding-id") }.
            to raise_error(RiakCsBroker::ServiceInstances::BindingAlreadyExists)
        end
      end

      context "when it is already bound but not stored by the broker" do
        before do
          Fog::RiakCS::Provisioning::Mock.any_instance.stub(:create_user).and_raise(Fog::RiakCS::Provisioning::UserAlreadyExists)
        end

        it "raises BindingAlreadyExists" do
          expect { service_instances.bind("my-instance", "some-binding-id") }.
            to raise_error(RiakCsBroker::ServiceInstances::BindingAlreadyExists)
        end
      end

      context "when Riak CS is not available" do
        before do
          Fog::RiakCS::Provisioning::Mock.any_instance.stub(:create_user).and_raise(Fog::RiakCS::Provisioning::ServiceUnavailable)
        end

        it "raises ServiceUnavailable" do
          expect { service_instances.bind("my-instance", "some-binding-id") }.
            to raise_error(RiakCsBroker::ServiceInstances::ServiceUnavailable)
        end
      end
    end
  end

  describe '#bound?' do
    context "when the binding id has already been bound" do
      before do
        service_instances.add("my-instance")
        service_instances.bind("my-instance", "binding-id")
      end

      it "is true" do
        expect(service_instances).to be_bound("binding-id")
      end
    end

    context "when the binding id has not been bound" do
      it "is false" do
        expect(service_instances).not_to be_bound("binding-id")
      end
    end
  end
end