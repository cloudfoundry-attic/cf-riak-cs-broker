shared_examples_for "an endpoint that handles errors caused by missing config" do
  context "when the configuration environment variables are missing" do
    before do
      RiakCsBroker::App.class_variable_set(:@@instances, nil)
      ENV.stub(:[]).and_call_original
      ENV.stub(:[]).with('RIAK_CS_ACCESS_KEY_ID').and_return nil
      make_request
    end

    it "returns a 500 error code" do
      last_response.status.should == 500
    end

    it "returns a JSON response containing the error message" do
      last_response.body.should be_json_eql({ description: "Riak CS is not configured."}.to_json)
    end
  end
end