require 'syslog/logger'

class MultiLogger

  def initialize(name, logdev)
    @sys_logger = Syslog::Logger.new name
    @logger = Logger.new(logdev)
  end

  def method_missing(method_name, message)
    @logger.send(method_name, message)
    @sys_logger.send(method_name, message)
  end

end
