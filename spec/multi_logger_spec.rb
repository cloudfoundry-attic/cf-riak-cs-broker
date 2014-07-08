require 'spec_helper'
require 'multi_logger'

describe MultiLogger do
  let(:custom_logger) { MultiLogger.new('my_prog_name', $stderr) }

  it 'logs to syslog' do
    expect_any_instance_of(Syslog::Logger).to receive(:info).with('foo')
    custom_logger.info 'foo'
  end

  it 'logs to regular logs' do
    expect_any_instance_of(Logger).to receive(:info).with('foo')
    custom_logger.info 'foo'
  end

end
