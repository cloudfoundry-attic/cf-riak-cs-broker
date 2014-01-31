require 'spec_helper'

describe RiakCsBroker::ServiceInstances do
  class MyError < StandardError
  end

  let(:service_instances) { described_class.new(RiakCsBroker::Config.riak_cs) }

  describe "#initialize" do
    it "raises a ClientError if the client fails to initialize" do
      Fog::Storage.stub(:new).and_raise(MyError.new("some-error-message"))

      expect {service_instances}.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
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

      expect {service_instances.add("my-instance")}.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
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

      expect {service_instances.include?("my-instance")}.to raise_error(RiakCsBroker::ServiceInstances::ClientError, "MyError: some-error-message")
    end
  end
end