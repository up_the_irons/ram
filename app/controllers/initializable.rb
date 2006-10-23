#modify the Ruby the 'Class' class to affored automatic initialization of mixed-in modules.
class Class
  def included_modules
    @included_modules ||= []
  end
  
  alias_method :old_new, :new
  def new(*args, &block)
    obj = old_new(*args, &block)
    self.included_modules.each do |mod|
      mod.initialize(obj) if mod.respond_to?(:initialize)
    end
    obj
  end
end

module Initializable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def included(mod)
      if mod.class != Module #in case Initializerable is mixed-into a class
        puts "Adding #{self} to #{mod}'s included_modules" if $DEBUG
        mod.included_modules << self
      end
    end
  end
end


