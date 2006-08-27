require File.dirname(__FILE__) + '/../test_helper'
require 'inbox_controller'

# Re-raise errors caught by the controller.
class InboxController; def rescue_action(e) raise e end; end

class InboxControllerTest < Test::Unit::TestCase
  fixtures :users, :profiles,:people,:collections,:memberships,:linkings
  def setup
    @controller = InboxController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_get_index
      login_as :quentin
      get :index
      assert_response :success
      assert assigns(:user)
  end
  
  def test_shall_redirect_unless_logged_in
      get :index
      assert_redirected_to :controller=>'account',:action=>'login'
  end
end
