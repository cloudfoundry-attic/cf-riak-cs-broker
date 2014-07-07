require "spec_helper"

describe "The service broker catalog" do
  subject do
    get "/v2/catalog"
  end

  it "returns an Unauthorized HTTP response" do
    expect(subject.status).to eq(401)
  end

  context "when authenticated", :authenticated do
    it "should include a list of services" do
      expect(subject.body).to have_json_path("services")
    end

    it "should include a service GUID" do
      expect(subject.body).to have_json_path("services/0/id")
    end

    it "should include a service name" do
      expect(subject.body).to have_json_path("services/0/name")
    end

    it "should include a service description" do
      expect(subject.body).to have_json_path("services/0/description")
    end

    it "should include a service bindable" do
      expect(subject.body).to have_json_path("services/0/bindable")
    end

    it "should include one plan" do
      expect(subject.body).to have_json_size(1).at_path("services/0/plans")
    end

    it "should include a plan for Bucket" do
      subject
      expect(last_response.body).to have_json_path("services/0/plans/0/id")
      expect(last_response.body).to have_json_path("services/0/plans/0/name")
      expect(last_response.body).to have_json_path("services/0/plans/0/description")
      expect(JSON.parse(last_response.body)["services"][0]["plans"][0]["name"]).to eq("bucket")
    end

    context "when optional metadata is provided" do
      it "contains proper metadata when it is (optionally) provided" do
        subject
        expect(last_response.body).to have_json_path("services/0/metadata")

        expect(last_response.body).to have_json_path("services/0/plans/0/metadata")
        expect(last_response.body).to have_json_path("services/0/plans/0/metadata/costs")
        expect(last_response.body).to have_json_path("services/0/plans/0/metadata/costs/0/amount")
        expect(last_response.body).to have_json_path("services/0/plans/0/metadata/costs/0/amount/usd")
        expect(last_response.body).to have_json_path("services/0/plans/0/metadata/costs/0/unit")
      end
    end
  end
end

