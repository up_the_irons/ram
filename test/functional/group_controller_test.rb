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
    login_as :quentin
  end
 
  def test_create_group
    
    assert_no_difference Group, :count do
      post :create, :group => { :name => '',:user_id=>User.find(:first).id }
      assert assigns(:group).new_record?
      assert_equal 1, assigns(:group).errors.count
    end
    
    assert_difference Group, :count  do
      post :create, :group => { :name =>'Guest Group',:user_id=>User.find(:first).id }
      assert_redirected_to :action => 'list'
      assert_equal 0, assigns(:group).errors.count
      assert assigns(:group)
    end
  end
  
  def test_shall_only_list_groups_within_access_scope
    login_as :user_4 #nolan bushnell
    get :list
    assert_equal User.find(4).groups, assigns(:groups) 
  end
  
  def test_update_group
    login_as :user_4
    g = User.find(4).groups.find(:first)
    new_name = 'Atari Monkeys'
    assert_not_nil g
    post :update, :id => g.id, :group =>{:name=>new_name}
    assert_response :redirect
    group_after_update = Group.find(g.id)
    assert_equal new_name, group_after_update.name
  end
  
  def test_prevent_update_on_get
    get :update
    assert_response :redirect
  end
  
  def test_prevent_create_on_get
    get :create
    assert_response :redirect
  end
  
  def test_show
    User.find(1).groups.each do |g|
      get :show, :id=> g.id
      assert assigns(:group)
    end
  end
  
  def test_deny_show_to_unauthorized_users
    login_as :user_4
     u = User.find(4)
     unauthorized_groups = Group.find(:all) - u.groups

      unauthorized_groups.each do |g|
        get :show, :id=> g.id
        assert_equal nil, assigns(:group)
      end
  end
  
  def test_destroy
    User.find(1).groups.each do |g|
      post :destroy, :id=>g.id
      assert :success
      assert_raise(ActiveRecord::RecordNotFound) {
        get :show, :id => g.id
      }
    end
  end
  
  def test_prevent_destroy_on_get
    get :destroy
    assert_response :redirect
  end
  
  def test_prevent_destroy_by_unauthorized_users
    login_as :user_7 #has no access to any groups 
    assert_no_difference Group, :count do
      post :destroy, :id=>Group.find(:first).id
    end
  end

end
