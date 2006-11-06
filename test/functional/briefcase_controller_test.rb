require File.dirname(__FILE__) + '/../test_helper'
require 'briefcase_controller'
require 'account_controller'

# Re-raise errors caught by the controller.
class BriefcaseController; def rescue_action(e) raise e end; end

class BriefcaseControllerTest < Test::Unit::TestCase
  include AuthenticatedTestHelper
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships
  
  
  def setup
    @controller = BriefcaseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_shall_list_briefcase_items
    login_as :quentin
    get :list
    assert :success
    assert_equal assigns(:flash)[:notice], "Your briefcase is empty."
  end
  
  def test_shall_create_briefcase_on_login
    @controller = AccountController.new
    post :login, :login => 'quentin', :password => 'qazwsx'
    @controller = BriefcaseController.new
    assert assigns(:session)[:user]    
    assert assigns(:session)[:briefcase]
    assert assigns(:session)[:briefcase].empty?
    assert_response :redirect
  end
  
  def test_admin_shall_add_item_to_briefcase
    login_as :quentin
     assert_difference @request.session[:briefcase], :size do
        @group, @asset = group_and_asset(current_user)
        post :add, :group_id=>@group.id, :assets=>[@asset.id]
     end
     assert_equal @request.session[:briefcase][0], @asset.id
     assert_equal assigns(:flash)[:notice], "Added (1) New Assets.<br/>"
     assert_response :redirect
  end
  
  def test_non_admin_shall_add_item_to_briefcase
    login_as :user_4
    assert_difference @request.session[:briefcase], :size do
        @group, @asset = group_and_asset(current_user)
        post :add, :group_id=>@group.id, :assets=>[@asset.id]
     end
     assert_equal @request.session[:briefcase][0], @asset.id
     assert_equal assigns(:flash)[:notice], "Added (1) New Assets.<br/>"
     assert_response :redirect
  end
  
  def test_shall_prevent_duplicate_adds
    login_as :quentin
    @group, @asset = group_and_asset(current_user)
    assert_difference @request.session[:briefcase], :size do
      post :add, :group_id=>@group.id, :assets=>[@asset.id]
    end
    
    assert_no_difference @request.session[:briefcase], :size do
      post :add, :group_id=>@group.id, :assets=>[@asset.id]
    end
    assert_equal assigns(:flash)[:notice], "(1) Assets could not be added because they already exist.<br/>"
  end
  
  def test_shall_prevent_ads_on_get
    login_as :quentin
    @group, @asset = group_and_asset(current_user)
    assert_no_difference @request.session[:briefcase], :size do
      get :add, :assets=>[@asset.id]
    end
    assert_redirected_to :action=>:index
  end
  
  def test_shall_prevent_adding_a_restricted_asset
    login_as :quentin
    assert_no_difference @request.session[:briefcase], :size do
      #FIXME: get_restricted_assets does not work.
      #restricted_asset = get_restricted_assets(current_user)[0].id
      post :add, :assets=>[7]
    end
    assert_response :redirect
  end
  
  def test_shall_delete_item_from_briefcase
    login_as :quentin
    add_item_for current_user
    assert_equal 1, @request.session[:briefcase].size
    
    assert_no_difference @request.session[:briefcase], :size do
      get :remove, :id=>@request.session[:briefcase][0]
    end
    assert_response :redirect
    
    before = @request.session[:briefcase].size
    assert_equal 1, @request.session[:briefcase].size
    post :remove, :assets=>[@request.session[:briefcase][0]]
    assert_equal before-1, @request.session[:briefcase].size
    assert_equal "Removed (1) Assets.<br/>", assigns(:flash)[:notice]
    assert_response :redirect
  end
    
  def test_shall_empty_entire_briefcase
    login_as :quentin
    assets = assets_for(current_user)
    assets.map{|a| @request.session[:briefcase] << a.id}
    assert_equal assets.size, @request.session[:briefcase].size
    
    get :remove_all 
    assert_equal assets.size, @request.session[:briefcase].size
    assert_response :redirect
    
    post :remove_all
    assert_equal 0, @request.session[:briefcase].size
    assert_response :redirect
  end
  
  def test_shall_zip_briefcase_for_download
    login_as :quentin
    assets = assets_for(current_user)
    assets.map{|a| @request.session[:briefcase] << a.id}
    assert_equal assets.size, @request.session[:briefcase].size
    assert @request.session[:briefcase].size > 0
    post :zip
    assert File.file?(assigns(:zip_file)), "Zip file should have been created."
    #clean up the newly created zip files.
    File.delete assigns(:zip_file)
    assert !File.file?(assigns(:zip_file)), "Zip file should have been deleted."
  end
  
  def test_zip_shall_mimic_category_hierarchy
    login_as :quentin
    assets = assets_for(current_user)
    assets.map{|a| @request.session[:briefcase] << a.id}
    assert_equal assets.size, @request.session[:briefcase].size
    assert @request.session[:briefcase].size > 0
    #breakpoint

  end
  
  protected
  def add_item_for(user)
    #get the first unique asset to add to the briefcase
    assets_for( user ).map do |a|
      return @request.session[:briefcase] << a.id unless @request.session[:briefcase].include? a.id
    end
  end
  
  def group_and_asset(user)
    group = current_user.groups[0] 
     [group , group.assets[0]]      
  end
  
  def get_restricted_assets(user)
    assets = []
    groups = Group.find(:all) - current_user.groups
    groups.each{|g| assets << g.assets}
    assets.flatten.uniq!
  end
  
  def current_user
    User.find(@request.session[:user])
  end
  def assets_for(user)
    assets = []
    user.groups.each{|g| assets << g.assets}
    assets = assets.flatten.uniq
  end
  
end
