require 'rubygems'
require 'rspec'
#require 'rspec/rails'

RSpec.configure do |config|
    config.expect_with :rspec do |expectations|
        expectations.syntax = :should
    end
end

require File.dirname(__FILE__) + '/../lib/atco'
