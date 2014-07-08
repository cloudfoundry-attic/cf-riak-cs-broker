ENV["RACK_ENV"] ||= "development"
require 'bundler/setup'
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

require 'json'
$stderr.sync=true

$:.unshift(File.expand_path('../../', __FILE__))
require 'riak_cs_broker/config'
require 'riak_cs_broker/service_instances'
require 'route_registrar'
require 'multi_logger'

module RiakCsBroker
  class App < Sinatra::Base
    use Rack::Auth::Basic, "Cloud Foundry Riak CS Service Broker" do |username, password|
      [username, password] == [Config.username, Config.password]
    end

    configure do
      Config.validate!
      RouteRegistrar.register!
    end

    before do
      content_type "application/json"
      Excon.defaults[:ssl_verify_peer] = Config.ssl_validation
      logger.info "Request:"
      logger.info sanitized_request
    end

    after do
      logger.info "Response Status:"
      logger.info response.status
      logger.info "Response Body"
      logger.info response.body
    end

    get '/v2/catalog' do
      RiakCsBroker::Config.catalog.to_json
    end

    put '/v2/service_instances/:id' do
      begin
        if instances.include?(params[:id])
          status 409
          logger.info("Could not provision #{params[:id]} because it already exists.")
        else
          instances.add(params[:id])
          status 201
        end
        "{}"
      rescue RiakCsBroker::ServiceInstances::ClientError => e
        logger.error(e.message)
        logger.error(e.backtrace)
        status 500
        { description: e.message }.to_json
      end
    end

    delete '/v2/service_instances/:id' do
      begin
        instances.remove(params[:id])
        status 200
        "{}"
      rescue RiakCsBroker::ServiceInstances::InstanceNotEmptyError
        logger.info("Could not deprovision a non-empty instance #{params[:id]}")
        status 409
        { description: "Could not unprovision because instance is not empty" }.to_json
      rescue RiakCsBroker::ServiceInstances::InstanceNotFoundError
        logger.info("Could not find the instance #{params[:id]}")
        status 410
        "{}"
      rescue RiakCsBroker::ServiceInstances::ClientError => e
        logger.error(e.message)
        logger.error(e.backtrace)
        status 500
        { description: e.message }.to_json
      end
    end

    put '/v2/service_instances/:id/service_bindings/:binding_id' do
      begin
        credentials = instances.bind(params[:id], params[:binding_id])
        status 201
        { "credentials" => credentials }.to_json
      rescue ServiceInstances::InstanceNotFoundError => e
        logger.info("Could not bind to an unknown service instance: #{params[:id]}")
        status 404
        { description: "Could not bind to an unknown service instance: #{params[:id]}" }.to_json
      rescue ServiceInstances::BindingAlreadyExistsError => e
        logger.info("Could not bind because of a conflict: #{e.message}")
        status 409
        "{}"
      rescue ServiceInstances::ServiceUnavailableError => e
        logger.error("Service unavailable: #{e.message}")
        status 503
        { description: "Could not bind because service is unavailable" }.to_json
      rescue RiakCsBroker::ServiceInstances::ClientError => e
        logger.error(e.message)
        logger.error(e.backtrace)
        status 500
        { description: e.message }.to_json
      end
    end

    delete '/v2/service_instances/:id/service_bindings/:binding_id' do
      begin
        instances.unbind(params[:id], params[:binding_id])
        status 200
        "{}"
      rescue ServiceInstances::InstanceNotFoundError => e
        logger.info("Could not unbind from an unknown service instance #{params[:id]}")
        status 410
        "{}"
      rescue ServiceInstances::BindingNotFoundError => e
        logger.info("Could not find the binding #{params[:binding_id]}")
        status 410
        "{}"
      rescue ServiceInstances::ServiceUnavailableError => e
        logger.error("Service unavailable: #{e.message}")
        status 503
        { description: "Could not bind because service is unavailable" }.to_json
      rescue RiakCsBroker::ServiceInstances::ClientError => e
        logger.error(e.message)
        logger.error(e.backtrace)
        status 500
        { description: e.message }.to_json
      end
    end

    def instances
      @instances ||= ServiceInstances.new(
        {
          host:              Config.riak_cs.host,
          port:              Config.riak_cs.port,
          scheme:            Config.riak_cs.scheme,
          access_key_id:     Config.riak_cs.access_key_id,
          secret_access_key: Config.riak_cs.secret_access_key,
        })
    end

    def logger
      settings.logger
    end

    private
    def sanitized_request
      {
        headers: filtered_request_headers,
        body: request.body.read,
        params: params
      }
    end

    def filtered_request_headers
      permitted_keys = %w(CONTENT_LENGTH
        CONTENT_TYPE
        GATEWAY_INTERFACE
        PATH_INFO
        QUERY_STRING
        REMOTE_ADDR
        REMOTE_HOST
        REQUEST_METHOD
        REQUEST_URI
        SCRIPT_NAME
        SERVER_NAME
        SERVER_PORT
        SERVER_PROTOCOL
        SERVER_SOFTWARE
        HTTP_ACCEPT
        HTTP_USER_AGENT
        HTTP_AUTHORIZATION
        HTTP_X_VCAP_REQUEST_ID
        HTTP_X_BROKER_API_VERSION
        HTTP_HOST
        HTTP_VERSION
        REQUEST_PATH)

      request.env.select { |key, val| permitted_keys.include? key }
    end
  end

  App.set :logger, MultiLogger.new('vcap.riak-cs-broker', $stderr)
end
