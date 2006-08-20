if RAILS_ENV == 'test'
  require 'todo_extension'
  Test::Unit::TestCase.send(:include, ToDoExtensionsPlugin::Test::Unit::TestCase)
end
