require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users, :profiles,:people,:collections,:memberships,:linkings, :events, :event_subscriptions, :event_triggers

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_login_and_redirect
    post :login, :login => 'administrator', :password => 'qazwsx'
    assert session[:user]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'administrator', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_shall_fail_login_for_pending_or_suspended_accounts
    post :login, :login => 'pending_user', :password => 'qazwsx'
    assert_response :success
    assert_equal flash[:error], "Your account is pending approval from the administrator."
    
    post :login, :login => 'suspended_user', :password => 'qazwsx'
    assert_response :success
    assert_equal flash[:error], "Your account is suspended."
    
    post :login, :login => 'deleted_user', :password => 'qazwsx'
    assert_response :success
    assert_equal flash[:error], "An account could not be found with that username or password"
  end

  def test_should_allow_signup
    assert_difference User, :count do
      create_user
      assert_response :redirect
    end
  end
  
  def test_should_save_last_login_time
    u  = User.find_by_login('administrator')
    ll = u.last_login_at
    post :login, :login => 'administrator', :password => 'qazwsx'
    assert_equal u.login , assigns(:current_user).login
    assert ll != assigns(:current_user).last_login_at
  end
  
  def test_should_have_an_empty_briefcase_at_login
    post :login, :login => 'administrator', :password => 'qazwsx'
    assert_equal assigns(:session)[:briefcase], []
  end

  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end
  
  # This should not require a user to be logged in.
  def test_should_recover_password
    user = users(:administrator)

    # Cannot change on get    
    assert_unchanged user,:password do
      get :forgot_password, :params=>{:login=>user.login,:email=>user.email}
      assert_response :success
    end
    
    # Require the username and email.
    assert_unchanged user,:password do
      post :forgot_password, :login=>user.login
      assert_response :redirect
      assert_equal "Both login and email are required to reset your account.", assigns(:flash)[:notice]
      
      post :forgot_password, :email=>user.email
      assert_response :redirect
      assert_equal "Both login and email are required to reset your account.", assigns(:flash)[:notice]
    end
        
    assert_changed user,:crypted_password do
      post :forgot_password, :login=>user.login,:email=>user.email
      assert_response :redirect
      assert assigns(:new_password)
      assert_equal "Your details have been sent to #{user.email}", assigns(:flash)[:notice]
    end    
    
    # Ensure you can now login
    post :login, :login => 'administrator', :password => assigns(:new_password)
    assert_equal user.login, assigns(:current_user).login
  end
  
  def test_should_allow_password_change
    login_as :administrator
    user = users(:administrator)
    new_pass = '1qaz2wsx3edc4rfv'
    assert_changed user,:crypted_password do
      post :edit, :id=>user.id, :user=>{:password=>new_pass,:password_confirmation=>new_pass}
    end
    
    # Now log out
    get :logout
    assert_nil session[:user]
    
    # Try to log in with new password.
    post :login, :login => 'administrator', :password => new_pass
    assert_equal user.login , assigns(:current_user).login
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
    login_as :administrator
    get :profile, :id=>'normal_user'
    assert assigns(:user)
    assert_equal User.find_by_login('normal_user') , assigns(:user)
    
    get :profile, :id=> assigns(:user).id
    assert assigns(:user)
    assert_equal User.find_by_login('normal_user') , assigns(:user)
  end
  
  def test_should_save_the_last_login_time_each_time_a_user_logs_in
    old_time = User.find_by_login('administrator').last_login_at
    post :login, :login => 'administrator', :password => 'qazwsx'
    assert session[:user]
    assert old_time != User.find_by_login('administrator').last_login_at
  end
  
  def test_shall_allow_session_based_toggling_of_side_menu
    login_as :administrator
    assert_equal true, @request.session[:view][:expand_menu]
    xhr :get, :toggle_menu
    assert_equal false, @request.session[:view][:expand_menu]
  end

  def test_should_logout
    login_as :administrator
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end
  
  def test_should_edit_info
    login_as :administrator
    get :edit, :id=>users(:administrator).id
    assert assigns(:user)
    assert assigns(:profile)
    assert assigns(:person)
  end
  
  def test_users_shall_only_edit_their_profile
    login_as :normal_user # Non-admin
    @user = users(:normal_user)
    assert @user.profile
    assert @user.person
    get :edit, :id=>users(:normal_user).id
    [:person,:profile].each do |sym|
      assert_equal assigns(sym).id, @user.send(sym).id
    end 
    
    post :edit, :id=>users(:normal_user).id, :person=>{:first_name=>'foo'}
    [:person,:profile].each do |sym|
      assert_equal assigns(sym).id, @user.send(sym).id
    end
  end
  
  def test_create_avatar
    login_as :normal_user # Non-admin
    file = "#{RAILS_ROOT}/test/fixtures/images/rails.png"
    temp_file = uploaded_jpeg(file)
    assert_difference Avatar, :count, 1 do # There is 1 new avatar
      post :edit, :avatar=>{:uploaded_data=>temp_file}
      assert assigns(:avatar)
      assert_equal assigns(:avatar).user_id, users(:normal_user).id
    end
    assert_response :success
  end
  
  def test_shall_skip_avatar_without_rmagick
    $APPLICATION_SETTINGS.preferences[:rmagick?] = false
    login_as :normal_user # Non-admin
    file = "#{RAILS_ROOT}/test/fixtures/images/rails.png"
    temp_file = uploaded_jpeg(file)
    assert_no_difference Avatar, :count do
      post :edit, :avatar=>{:uploaded_data=>temp_file}
      assert !assigns(:avatar)
    end
    assert_response :success
    $APPLICATION_SETTINGS.preferences[:rmagick?] = true # rollback
  end
  
  def test_users_shall_not_edit_status_or_login
    login_as :normal_user # Non-admin
    @user = users(:normal_user)
    state = @user.state
    email = @user.email
    login = @user.login
    post :edit, :id=>@user.id, :user=>{:login=>"Foo_#{Time.now.to_s}",:state=>9,:email=>'foo-bar-baz@bar.com'}
    assert_response :success
    assert_equal assigns(:user).email, 'foo-bar-baz@bar.com' # Password was changed
    assert_equal assigns(:user).state, state # State was not changed.
    assert_equal assigns(:user).login, login # State was not changed.
  end

  protected

  def create_user(options = {})
    post :signup, :user => { :login => 'quire', :email => 'quire@example.com', 
                             :password => 'qazwsx', :password_confirmation => 'qazwsx' }.merge(options)
  end
  
  def a_profile(opts={})
    t = Time.now.to_s
    @attributes={
                :city=>"city_#{t}", 
                :address_line1=>"address_line1_#{t}", 
                :postal_code=>"postal_code_#{t}",
                :address_line2=>"address_line2_#{t}",
                :country=>"",
                :fax=>"fax_#{t}",
                :telephone=>"telephone_#{t}",
                :bio=>"Bio_#{t}",
                :state=>"state_#{t}"
                }
  end
end
