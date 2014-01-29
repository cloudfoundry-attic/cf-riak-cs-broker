require 'yaml'

module RiakCsBroker
  module Config
    def self.[](key)
      @config[key]
    end

    def self.load_config(filename = default_filename)
      @config ||= if File.exists?(filename)
                    YAML.load_file(filename)
                  else
                    $stderr.puts "ERROR: No configuration file found at #{filename}."
                    {}
                  end
    end

    def self.default_filename
      File.expand_path('../../../config/broker.yml', __FILE__)
    end
  end
end