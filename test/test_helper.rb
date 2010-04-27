ENV["RAILS_ENV"] = "test"

require 'test/unit'
require 'rubygems'
require 'logger'
require 'active_support'
require 'active_support/test_case'

# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end

 
require 'boot' unless defined?(ActiveRecord)
require 'pp'
