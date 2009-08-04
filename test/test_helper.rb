require 'test/unit'
require 'pp'

require File.join(File.dirname(__FILE__), '../lib/tmail_patches')
# require 'rubygems'
# require 'tmail'

FIXTURES_PATH = File.join(File.dirname(__FILE__), 'fixtures') unless defined? FIXTURES_PATH
def load_fixture(name)
  TMail::Mail.load(File.join(FIXTURES_PATH, name))
end
