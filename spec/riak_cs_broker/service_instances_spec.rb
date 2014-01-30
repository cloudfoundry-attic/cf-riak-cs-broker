require 'spec_helper'

describe RiakCsBroker::ServiceInstances do
  let(:service_instances) { described_class.new(RiakCsBroker::Config['riak-cs']) }

  it "stores requested service instances" do
    service_instances.add("my-instance")
    expect(service_instances.include?("my-instance")).to be_true
  end

  it "does not include any instances that were never created" do
    expect(service_instances.include?("never-created")).to be_false
  end
end