require "spec_helper"

describe "The service broker catalog" do
  before(:each) do
    get "/v2/catalog"
  end

  it "returns an Unauthorized HTTP response" do
    last_response.status.should == 401
  end

  context "when authenticated", :authenticated do
    it "should include a list of services" do
      last_response.body.should have_json_path("services")
    end

    it "should include a service GUID" do
      last_response.body.should have_json_path("services/0/id")
    end

    it "should include a service name" do
      last_response.body.should have_json_path("services/0/name")
    end

    it "should include a service description" do
      last_response.body.should have_json_path("services/0/description")
    end

    it "should include a service bindable" do
      last_response.body.should have_json_path("services/0/bindable")
    end

    it "should include one plan" do
      last_response.body.should have_json_size(1).at_path("services/0/plans")
    end

    it "should include a plan for Bucket" do
      last_response.body.should have_json_path("services/0/plans/0/id")
      last_response.body.should have_json_path("services/0/plans/0/name")
      last_response.body.should have_json_path("services/0/plans/0/description")
      JSON.parse(last_response.body)["services"][0]["plans"][0]["name"].should == "bucket"
    end

    context "when optional metadata is provided" do
      it "contains proper metadata when it is (optionally) provided" do
        last_response.body.should have_json_path("services/0/metadata")

        last_response.body.should have_json_path("services/0/plans/0/metadata")
        last_response.body.should have_json_path("services/0/plans/0/metadata/costs")
        last_response.body.should have_json_path("services/0/plans/0/metadata/costs/0/amount")
        last_response.body.should have_json_path("services/0/plans/0/metadata/costs/0/amount/usd")
        last_response.body.should have_json_path("services/0/plans/0/metadata/costs/0/unit")
      end
    end
  end
end

