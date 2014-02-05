module RequestSpecHelpers
  def create_instance(id = instance_id)
    put "/v2/service_instances/#{id}"
  end
end

