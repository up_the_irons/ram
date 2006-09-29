require 'unchangeable'
ActiveRecord::Base.extend Unchangeable
require File.dirname(__FILE__) + '/lib/unchangeable'
