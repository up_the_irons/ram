require 'acts_as_subscribable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Subscribable)
require File.dirname(__FILE__) + '/lib/subscription'