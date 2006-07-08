require File.dirname(__FILE__) + '<%= '/..' * class_nesting_depth %>/../test_helper'
require '<%= file_path %>_controller'

# Re-raise errors caught by the controller.
class <%= class_name %>Controller; def rescue_action(e) raise e end; end

class <%= class_name %>ControllerTest < Test::Unit::TestCase
  def setup
    @controller = <%= class_name %>Controller.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
<% require 'application'
   ctrl = "#{class_name}Controller".constantize
   (ctrl.new.public_methods - ApplicationController.new.public_methods - ctrl.hidden_actions).each do |action| %>
  def test_action_<%= action %>
    assert_nothing_raised { get :<%= action %> }
  end
<% end %>
end
