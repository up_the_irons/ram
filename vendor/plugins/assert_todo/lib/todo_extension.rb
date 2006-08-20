

require 'action_controller/test_process'
    
module ToDoExtensionsPlugin
  module Test
    module Unit
      module TestResult
        def initialize
          @todo_count = 0
        end
        
        def add_todo
          @todo_count +=1
          notify_listeners(CHANGED, self)
        end
        
        def to_s
         "#{run_count} tests, #{assertion_count} assertions, #{failure_count} failures, #{error_count} errors, #{todo_count} todos"
        end
        
      end
      module TestCase #:nodoc:
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.class_eval do
            alias_method  :todo, :assert_todo
          end
        end        
        
        
        
        module InstanceMethods #:nodoc:
          def assert_todo(message = nil)
            stackLine =  caller(1)[0]
            stackLine=~/(\w*)\.rb\:(\w*)\:\s*in\s*\`(\w*)'/

            puts "-----------------------------------"
            puts "TODO   : #{message}"
            puts "Class  : Oxxxx{::#{$1}:::>"
            puts "Method : #{$3}"
            puts "Line   : #{$2}"
            puts "-----------------------------------"
            puts
            #add_todo(message)
            
          end
        end
        
      end
    end
  end
end
