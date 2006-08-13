require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users, :profiles,:people,:collections,:memberships,:linkings

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_login_and_redirect
    post :login, :login => 'quentin', :password => 'quentin'
    assert session[:user]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_shall_fail_login_for_pending_or_suspended_accounts
    post :login, :login => 'pending_user', :password => 'qazwsx'
    assert_response :success
    assert_equal flash[:error], "Your Account is pending approval from the administrator"
    
    post :login, :login => 'suspended_user', :password => 'qazwsx'
    assert_response :success
    assert_equal flash[:error], "Your Account is Suspended"
  end

  def test_should_allow_signup
    assert_difference User, :count do
      create_user
      assert_response :redirect
    end
  end
  
  def test_should_save_last_login_time
    u  = User.find_by_login('quentin')
    ll = u.last_login_at
    post :login, :login => 'quentin', :password => 'quentin'
    assert_equal u.login , assigns(:current_user).login
    assert ll != assigns(:current_user).last_login_at
  end
  
  def test_should_have_an_empty_folio_at_login
    post :login, :login => 'quentin', :password => 'quentin'
    assert_equal assigns(:session)[:folio], []
  end

  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end
  
  def test_shall_find_users_by_login_or_by_id
    login_as :quentin
    get :profile, :id=>'nolan_bushnell'
    assert assigns(:user)
    assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)
    
    get :profile, :id=> assigns(:user).id
    assert assigns(:user)
    assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)
  end
  
  def test_should_save_the_last_login_time_each_time_a_user_logs_in
    old_time = User.find_by_login('quentin').last_login_at
    post :login, :login => 'quentin', :password => 'quentin'
    assert session[:user]
    assert old_time != User.find_by_login('quentin').last_login_at
    
  end
  

  def test_should_logout
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  protected
  def create_user(options = {})
    post :signup, :user => { :login => 'quire', :email => 'quire@example.com', 
                             :password => 'quire', :password_confirmation => 'quire' }.merge(options)
  end
end
