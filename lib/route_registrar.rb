require 'riak_cs_broker/config'
require 'cf-registrar'

class RouteRegistrar
  def self.register!
    return if ['development', 'test'].include? ENV['RACK_ENV']

    register_thread = Thread.new do
      max_fixnum = (2**(0.size * 8 -2) -1)

      NATS.start(:uri => RiakCsBroker::Config.message_bus_servers, :max_reconnect_attempts => max_fixnum) do
        registrar.register_with_router
      end
    end

    Kernel.at_exit do
      register_thread.kill
      register_thread.join

      NATS.start(:uri => RiakCsBroker::Config.message_bus_servers) do
        registrar.shutdown { EM.stop }
      end
    end
  end

  private

  def self.registrar
    Cf::Registrar.new(
      :message_bus_servers => RiakCsBroker::Config.message_bus_servers,
      :host                => RiakCsBroker::Config.ip,
      :port                => RiakCsBroker::Config.port,
      :uri                 => RiakCsBroker::Config.external_host,
      :tags                => { "component" => "P-CS" })
  end
end
