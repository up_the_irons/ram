require File.dirname(__FILE__) + '/../test_helper'
require 'collections_controller'

# Re-raise errors caught by the controller.
class CollectionsController; def rescue_action(e) raise e end; end

class CollectionsControllerTest < Test::Unit::TestCase
  fixtures :collections

  def setup
    @controller = CollectionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

 #todo not sure this needs to be tested since it is just the base of the STI
 
 def test_true
  assert true
 end
end
