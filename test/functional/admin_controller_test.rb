module IncludedTests; end
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/admin_controller_test/group_methods_test'
require File.dirname(__FILE__) + '/admin_controller_test/category_methods_test'
require File.dirname(__FILE__) + '/admin_controller_test/user_methods_test'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships
  include IncludedTests::UserMethodsTest
  include IncludedTests::GroupMethodsTest
  include IncludedTests::CategoryMethodsTest
  
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @existing_category_id = 8
    @user_with_access_to_all_categories = 1
    @user_with_access_to_no_categories = 7
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
  
  
  def test_admin_shall_assign_groups_to_categories
  
  end
    
end
