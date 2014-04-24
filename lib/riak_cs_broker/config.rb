ENV['SETTINGS_PATH'] ||= File.expand_path('../../../settings.yml', __FILE__)

module RiakCsBroker
  class Config < Settingslogic

    source ENV['SETTINGS_PATH']
    load!

    def self.validate!
      # SettingsLogic throws an exception when a setting is accessed, but
      # has not been populated through the yml file.  So, we will just
      # access settings we want to validate and let SettingsLogic trow an exception
      # if a setting is not populated.

      self.riak_cs
      self.riak_cs.host
      self.riak_cs.port
      self.riak_cs.access_key_id
      self.riak_cs.secret_access_key

      self.ssl_validation
      self.username
      self.password
    end
  end
end
