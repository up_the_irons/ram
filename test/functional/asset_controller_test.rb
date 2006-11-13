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
    login_as :quentin
    @user = users(:quentin)

  end

  # TODO: Not sure this needs to be tested since it is just the base of the STI
  def test_bulk_upload
   get :bulk_upload, :id=>@category_with_asset
   assert_equal assigns(:login), CGI.escape(@user.encrypt_login)
   assert_response :success
   assert assigns(:url_params)
  end
  
  def test_create_en_masse
    get :create_en_masse
    assert_redirected_to :controller=>'inbox'
    post :create_en_masse, :hash=>CGI.escape(@user.encrypt_login), :user=>{:group_ids=>[@user.groups.join(",")]}
    
    # TODO: Find a way to stub out the flash portions of the app so that they too can be tested.
  end
  
  def test_add_and_remove_groups
    a = @user.assets[0]
    assert a.groups.size > 1 # At least two groups
    group_to_keep = a.groups[0].id 
    another_group = a.groups[1].id # Used in the get request below
    post :edit, :id=>a.id,:asset=>{:group_ids=>[ group_to_keep ]} # Only submit one groups
    assert_response :success
    assert_equal 1, assigns(:asset).groups.size
    assert assigns(:asset).groups[0].id, group_to_keep
    
    # Can't assign groups on assets
    assert_no_difference assigns(:asset).groups, :count do
      get :edit, :id=>a.id,:asset=>{:group_ids=>[group_to_keep, another_group]}
    end
    assert_response :success
    
    # Assign a new group to the asset
    assert_difference assigns(:asset).groups, :count do
      post :edit, :id=>a.id,:asset=>{:group_ids=>[group_to_keep, another_group]}
    end
    assert_equal 2, assigns(:asset).groups.size
  end
  
  
  def test_create
    file = "#{RAILS_ROOT}/test/fixtures/images/rails.png"
    temp_file = uploaded_jpeg(file)
    assert_difference Asset, :count, 4 do # There is 1 new asset and 3 new thumbnails
      post :edit, :asset=>{:description=>"I made this asset on #{Time.now.to_s}", :category_id=>@category_with_asset, :user_id=>@user.id, :uploaded_data=>temp_file}
      assert assigns(:asset)
      assert_equal 3, assigns(:asset).thumbnails.size
    end
    assert_redirected_to :action=>'edit',:id=>assigns(:asset).id
  end
  
  def test_update
    asset = @user.assets[0]
    another_cat = (@user.categories - [Category.find(asset.category_id)])[0]
    another_description = "foo's birthday is #{Time.now.to_s}"
    another_user = User.find(2)
    props = {:description=>another_description,:category_id=>another_cat.id,:user_id=>another_user.id}
    props.each_pair do |k,v|
      assert asset[k] != v
    end
    post :edit, :id=>asset.id, :asset=>props
    assert_response :success
    assert assigns(:asset).description == props[:description]
    assert assigns(:asset).category_id == props[:category_id]
    assert assigns(:asset).user_id != props[:user_id] # To prevent URL hacking user_ids are not allowed to change through mass assignment
  end
  
  def test_shall_not_add_the_same_group_twice
    asset = @user.assets[0]
    assert asset.groups.size > 0
    assert_no_difference asset.groups, :count do
      post :edit, :id=>asset.id, :asset=>{:group_ids=>asset.groups.map{|g| g.id} }
    end
    assert assigns(:asset).groups.size > 0
    assert_response :success
  end
  
  def test_delete_asset
    cat = @user.categories[0]
    @a = an_asset({:user_id=>@user.id,:category_id=>cat.id})
    @a.groups << @user.groups[0]
    post :destroy, :id=>@a.id
    assert assigns(:flash)[:notice] = 'Your asset was deleted.'
    assert_redirected_to :controller=>'category', :action=>'show', :id=>@a.category_id
    assert_raise(ActiveRecord::RecordNotFound) do
      Asset.find(@a.id)
    end
  end
   
  def test_shall_prevent_destroy_on_gets
    @a = @user.assets[0]
    assert_no_difference Asset, :count do
      get :destroy, :id=>@a.id
      assert assigns(:flash)[:notice] = 'Could not delete asset.'
    end
    assert_redirected_to :controller=>'inbox'
  end
    
  def test_shall_prevent_deletes_without_access
    @a = @user.assets[0]
    login_as :user_7
    assert_no_difference Asset, :count do
      post :destroy, :id=>@a.id
      assert assigns(:flash)[:notice] = 'Could not delete asset.'
      assert_redirected_to :controller=>'inbox'
    end
  end
  
  def test_shall_accept_tags
    @controller = CategoryController.new
  
    get :show, :id=>@category_with_asset, :display=>'assets'
    assert :success
    assert assigns(:assets)
    @controller = AssetController.new
    get :show, :id=>assigns(:assets)[0].id
    assert :success
    assert assigns(:asset)
    before = assigns(:asset).tags.size
    assert_equal assigns(:asset).tags.include?("ruby on rails"), false
    # Add new tags
    post :edit, :id=>1, :asset=>{:category_id=>@category_with_asset,:tags=>"\"ruby on rails\", logo"}
    assert_equal assigns(:asset).tags.size, 2
    assert assigns(:asset).tags.include?("ruby on rails")
  end
  
  def test_shall_display_tags
    @controller = CategoryController.new
    get :show, :id=>@category_with_asset, :display=>'assets'
    assert :success
    assert assigns(:assets)
    @controller = AssetController.new
    get :show, :id=>assigns(:assets)[0].id
    assert :success
    assert assigns(:asset)
    assert assigns(:asset).tags.size > 0
  end 
end
