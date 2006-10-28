# EnlightenObservers is a controller module that will give your ActiveRecord::Observer objects the ability to see the
# controller context in which they were called.
#
# To use EnlightenObservers, perform the following in your controller:
#
# 1. include EnlightenObservers 
# 2. Instantiate your observers using the observer() method
#
# For example:
#
# class MyController < ActionController::Base
#   include EnlightenObservers
#
#   observer :my_observer
# end
#
# Step #2 is important because one of the more common ways to instantiate observers is to include them in your
# environment.rb, and doing so will cause no errors, but this module will not "turn on" if you do so.  So don't forget 
# this step.

module EnlightenObservers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def observer(*observers)
      super

      configuration = observers.last.is_a?(Hash) ? observers.pop : {}
      observers.each do |observer|
        observer_instance = Object.const_get(Inflector.classify(observer)).instance
        class <<observer_instance
          include Enlightenment
        end

        around_filter(observer_instance, :only => configuration[:only]) 
      end
    end
  end

  module Enlightenment
    def self.included(base)
      base.module_eval do
        attr_accessor :controller
      end
    end

    def before(controller)
      self.controller = controller
    end

    def after(controller)
      self.controller = nil # Clean up for GC
    end
  end
end
