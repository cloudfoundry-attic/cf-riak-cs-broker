require 'spec_helper'

describe RiakCsBroker::Config do
  describe "self.basic_auth" do
    it "returns username and password" do
      ENV.stub(:[]).and_call_original
      ENV.stub(:[]).with('RIAK_CS_BROKER_USERNAME').and_return "user"
      ENV.stub(:[]).with('RIAK_CS_BROKER_PASSWORD').and_return "password"

      RiakCsBroker::Config.basic_auth[:username].should eq("user")
      RiakCsBroker::Config.basic_auth[:password].should eq("password")
    end
  end

  describe "self.service_instance_config" do
    it "returns configuration" do
      RiakCsBroker::Config.riak_cs.should include(:host, :port, :scheme, :access_key_id, :secret_access_key)
    end

    it "does not raise an error if 'scheme' is missing" do
      ENV.stub(:[]).and_call_original
      ENV.stub(:[]).with('RIAK_CS_SCHEME').and_return nil

      expect { RiakCsBroker::Config.riak_cs }.to_not raise_error
    end

    it "raises ConfigError if 'host', 'port', 'access_key_id', or 'secret_access_key' is missing" do
      ENV.stub(:[]).and_call_original
      ENV.stub(:[]).with('RIAK_CS_HOST').and_return nil

      expect { RiakCsBroker::Config.riak_cs }.to raise_error(RiakCsBroker::Config::ConfigError, "Riak CS is not configured.")
    end
  end
end