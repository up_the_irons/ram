require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_helper'
require 'category_controller'

# Re-raise errors caught by the controller.
class CategoryController; def rescue_action(e) raise e end; end

class CategoryControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships
  def setup
    @controller = CategoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @@existing_category_id = 8
    login_as :quentin
    
    @@user_with_access_to_all_categories = 1
    @@user_with_access_to_no_categories = 7
  end

  def test_category_shall_display_a_list_of_assets
    get :show, :id=>6
    assert assigns(:assets)
  end
  
  def test_category_shall_display_a_list_of_groups
    get :show, :id=>6
    assert assigns(:category)
    assert assigns(:groups)
  end
  
  
  
  def test_add_group_to_category
    c = Category.find(@@existing_category_id)
    s = c.groups.size
    post :add_group, :id=>c.id, :group_id=> 1, :update=>'new_group_form'
    assert flash[:notice] == 'Your Group has been added'
    assert_equal Category.find(@@existing_category_id).groups.size, s+1   
  end
  
  def test_user_shall_not_add_a_group_to_a_category_that_they_do_not_belong_to
    login_as :user_7
    c = Category.find(@@existing_category_id)
    s = c.groups.size
    post :add_group, :id=>c.id, :group_id=> 1, :update=>'new_group_form'
    assert flash[:notice] == 'This group could not be located within your account.'
    assert_equal Category.find(@@existing_category_id).groups.size, s
  end
  
  def test_user_shall_not_see_a_restricted_groups_assets_in_a_category
    login_as :user_7
    get :show, :id=>6
    assert_equal nil, assigns(:assets)
  end
  
  def test_user_shall_not_be_a_able_to_show_a_restricted_category
     login_as :user_4
     u = User.find(4)
     unauthorized_categories = Category.find(:all) - u.categories

      unauthorized_categories.each do |c|
        get :show, :id=> c.id
        assert_equal nil, assigns(:category)
      end
  end
  
  def test_remove_group_from_category
    s = Category.find(6).groups.size
    post :remove_group, :id=>6, :group_id=>1
    assert_equal Category.find(6).groups.size, s-1
    assert assigns(:category)
  end
  
  def test_show_category_scoped_to_users_access
    login_as :user_4
    u = User.find(4) 
    u.categories.each do |c|
      get :show, :id=> c.id
      assert_response :success, "Should show category #{c.id}"
      assert assigns(:category)
    end
  end
  
  def test_removing_group_from_category_removes_assets_linked_only_to_that_group
    
  end
  
  def test_destroy_category_with_and_without_children
      #no children to destroy
      assert_difference Category, :count, -1 do
        post :destroy, :id => 15
        assert_redirected_to :action => 'list'
      end
      #three children to destroy
      assert_difference Category, :count, -4 do
        post :destroy, :id => 10
        assert_redirected_to :action => 'list'
      end
      #already deleted
      assert_no_difference Category, :count do
        assert_raise(ActiveRecord::RecordNotFound) {
          post :destroy, :id => 10
        }
      end
  end
end
