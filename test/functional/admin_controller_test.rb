require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :quentin #has admin_rights
  end
  
  def test_shall_redirect_to_index_when_a_non_admin_accesses_controller
    login_as :user_7
    get :index
    assert_redirected_to :controller=>'account', :action=>'index'
  end
  
  def test_shall_allow_admin_access
    get :index
    assert_redirected_to :action=>'dashboard'
  end
  
  def test_shall_list_users
    get :list_users
    assert :success
    assert assigns(:users)
  end
  
  def test_shall_list_groups
    get :list_groups
    assert :success
    assert assigns(:groups)
  end
  
  def test_shall_list_categories
      get :list_categories
      assert :success
      assert assigns(:categories)
  end
  
  def test_shall_find_users_by_login_or_by_id
    login_as :quentin
    get :show_user, :id=>'nolan_bushnell'
    assert assigns(:user)
    assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)
    
    get :show_user, :id=> assigns(:user).id
    assert assigns(:user)
    assert_equal User.find_by_login('nolan_bushnell') , assigns(:user)
  end
  
  def test_shall_show_groups
    login_as :quentin
    get :show_group, :id=>2
    assert assigns(:group)
    assert assigns(:non_members)
    assert_equal assigns(:group).users - assigns(:non_members), assigns(:group).users
  end
  
  def test_admin_shall_remove_users_from_groups
  
  end
  
  def test_admin_shall_assign_groups_to_categories
  
  end
  
  def test_admin_shall_edit_categories
  
  end
  
  def test_admin_shall_edit_groups
  
  end
  
  def test_admin_shall_edit_users
  
  end
  
end
