require 'has_a_collection'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::HasACollection)
require File.dirname(__FILE__) + '/lib/subscription'