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
    login_as :administrator
    
    @@user_with_access_to_all_categories = 1
    @@user_with_access_to_no_categories = 7
  end

  def test_category_shall_display_a_list_of_assets
    get :show, :id=>6, :display=>'assets'
    assert assigns(:assets)
  end
  
  def test_category_shall_display_a_list_of_groups
    get :show, :id=>6
    assert assigns(:category)
    assert assigns(:groups)
  end
    
  def test_user_shall_not_see_a_restricted_groups_assets_in_a_category
    login_as :user_without_group_memberships
    get :show, :id=>6
    assert_equal nil, assigns(:assets)
  end
  
  def test_user_shall_not_be_a_able_to_show_a_restricted_category
    login_as :normal_user
    u = User.find(4)
    unauthorized_categories = Category.find(:all) - u.categories

    unauthorized_categories.each do |c|
      get :show, :id=> c.id
      assert_equal nil, assigns(:category)
    end
  end
  
  def test_show_category_scoped_to_users_access
    login_as :normal_user
    u = User.find(4) 
    u.categories.each do |c|
      get :show, :id=> c.id
      assert_response :success, "Should show category #{c.id}"
      assert assigns(:category)
    end
  end
  
  def test_index_shows_root_category
    login_as :normal_user
    u = User.find(4)
    get :index
    root = assigns(:current_user).categories_as_tree{:root}[:root][:children][0][:id]
    assert_redirected_to :action=>'show', :id=>root
  end

  def test_show_pagination_format
    get :show, :id => collections(:collection_9).id

    assert @response.body =~ /Page 1.* 1 - 2 of 2/
    assert @response.body =~ /Rows \/ Page:.*<span class="selected">10<\/span>/m
  end

end
