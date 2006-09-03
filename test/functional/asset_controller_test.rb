require File.dirname(__FILE__) + '/../test_helper'
require 'asset_controller'

# Re-raise errors caught by the controller.
class AssetController; def rescue_action(e) raise e end; end

class AssetControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships, :tags, :taggings

  def setup
    @controller = AssetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @category_with_asset = 8
  end

 #todo not sure this needs to be tested since it is just the base of the STI
 def test_bulk_upload
  login_as :quentin
  @user = User.find(@request.session[:user])
  get :bulk_upload, :id=>@category_with_asset
  assert_equal assigns(:login), CGI.escape(@user.encrypt_login)
  assert_response :success
  assert assigns(:url_params)
 end
 
 def test_create_en_masse
   login_as :quentin
   get :create_en_masse
   assert_redirected_to :action=>:index
   login_as :quentin
   @user = User.find(@request.session[:user])
   post :create_en_masse, :hash=>CGI.escape(@user.encrypt_login)
   assert_redirected_to :action=>:upload_results
 end

 def test_assigned_and_remaining_groups
   todo
 end
 
 def test_remove_from_group
   todo
 end
 
 def test_add_to_group
  todo
 end
 
 def test_shall_not_remove_from_group_on_get
   todo
 end
 
 def test_shall_not_add_group_from_get
  todo
 end
 
 def test_destroy
  todo
 end
 
 def test_create
  todo
 end
 
 def test_update
  todo
 end
 
 def test_shall_accept_tags
  login_as :quentin
  @controller = CategoryController.new
  
  get :show, :id=>@category_with_asset
  assert :success
  assert assigns(:assets)
  @controller = AssetController.new
  get :show, :id=>assigns(:assets)[0].id
  assert :success
  assert assigns(:asset)
  before = assigns(:asset).tags.size
  assert_equal assigns(:asset).tags.include?("ruby on rails"), false
  #add new tags
  post :update, :id=>1,:category_id=>@category_with_asset, :update=>"asset_form", :asset=>{:tags=>"\"ruby on rails\", logo"}
  assert_equal assigns(:asset).tags.size, 2
  assert assigns(:asset).tags.include?("ruby on rails")
 end
 
 def test_shall_display_tags
   login_as :quentin
   @controller = CategoryController.new
   get :show, :id=>@category_with_asset
   assert :success
   assert assigns(:assets)
   @controller = AssetController.new
   get :show, :id=>assigns(:assets)[0].id
   assert :success
   assert assigns(:asset)
   assert assigns(:asset).tags.size > 0
 end
 
 def test_shall_not_add_the_same_group_twice
  todo
 end
 
 def test_shall_not_upload_the_same_asset_twice_to_identical_categories
   todo
 end
 
 def test_shall_only_present_select_options_from_unassigned_groups
   todo
 end
 
 def test_shall_prevent_users_from_uploading_to_restricted_groups
  todo
 end
 
end
