shared_examples_for "an endpoint that handles errors when accessing Riak CS" do
  it "returns a 500 error code" do
    make_request
    expect(last_response.status).to eq(500)
  end

  it "returns a JSON response containing the error message" do
    make_request
    expect(last_response.body).to be_json_eql({ description: "some-error-message"}.to_json)
  end
end
