require File.dirname(__FILE__) + '/../test_helper'
require 'group_controller'

# Re-raise errors caught by the controller.
class GroupController; def rescue_action(e) raise e end; end

class GroupControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships

  def setup
    @controller = GroupController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :administrator
  end
  
  def test_shall_only_list_groups_within_access_scope
    login_as :normal_user # Nolan bushnell
    get :list
    assert_equal User.find(4).groups, assigns(:groups) 
  end
  
  def test_show
    User.find(1).groups.each do |g|
      get :show, :id=> g.id
      assert assigns(:group)
    end
  end
  
  def test_deny_show_to_unauthorized_users
    login_as :normal_user
    u = User.find(4)
    unauthorized_groups = Group.find(:all) - u.groups

    unauthorized_groups.each do |g|
      get :show, :id=> g.id
      assert_equal nil, assigns(:group)
    end
  end

end
