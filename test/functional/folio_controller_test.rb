require File.dirname(__FILE__) + '/../test_helper'
require 'folio_controller'
require 'account_controller'

# Re-raise errors caught by the controller.
class FolioController; def rescue_action(e) raise e end; end

class FolioControllerTest < Test::Unit::TestCase
  include AuthenticatedTestHelper
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships
  
  
  def setup
    @controller = FolioController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_shall_list_folio_items
    login_as :quentin
    get :list
    assert :success
    assert_equal assigns(:flash)[:notice], "Your folio is empty."
  end
  
  def test_shall_create_folio_on_login
    @controller = AccountController.new
    post :login, :login => 'quentin', :password => 'qazwsx'
    @controller = FolioController.new
    assert assigns(:session)[:user]    
    assert assigns(:session)[:folio]
    assert assigns(:session)[:folio].empty?
    assert_response :redirect
  end
  
  def test_shall_add_item_to_folio
    login_as :quentin
     assert_difference @request.session[:folio], :size do
        @group, @asset = group_and_asset(current_user)
        post :add, :group_id=>@group.id, :asset_id=>@asset.id
     end
     assert_equal @request.session[:folio][0], @asset.id
     assert_equal assigns(:flash)[:notice], "#{@asset.name} was added to your folio"
     assert_response :redirect
  end
  
  def test_shall_prevent_duplicate_adds
    login_as :quentin
    @group, @asset = group_and_asset(current_user)
    assert_difference @request.session[:folio], :size do
      post :add, :group_id=>@group.id, :asset_id=>@asset.id
    end
    
    assert_no_difference @request.session[:folio], :size do
      post :add, :group_id=>@group.id, :asset_id=>@asset.id
    end
    assert_equal assigns(:flash)[:notice], "#{@asset.name} is already in your folio"
  end
  
  def test_shall_prevent_ads_on_get
    login_as :quentin
    @group, @asset = group_and_asset(current_user)
    assert_no_difference @request.session[:folio], :size do
      get :add, :group_id=>@group.id, :asset_id=>@asset.id
    end
    assert_redirected_to :action=>:index
  end
  
  def test_shall_prevent_adding_a_restricted_asset
    login_as :quentin
    assert_no_difference @request.session[:folio], :size do
      #FIXME: get_restricted_assets does not work.
      #restricted_asset = get_restricted_assets(current_user)[0].id
      post :add, :group_id=>current_user.groups[0].id, :asset_id=>7
    end
    assert_equal assigns(:flash)[:notice], "The requested asset could not be located on the server."
    assert_response :redirect
  end
  
  def test_shall_delete_item_from_folio
    login_as :quentin
    add_item_for current_user
    assert_equal 1, @request.session[:folio].size
    
    assert_no_difference @request.session[:folio], :size do
      get :remove, :id=>@request.session[:folio][0]
    end
    assert_response :redirect
    
    before = @request.session[:folio].size
    assert_equal 1, @request.session[:folio].size
    post :remove, :id=>@request.session[:folio][0]
    assert_equal before-1, @request.session[:folio].size
    assert_equal assigns(:flash)[:notice], "You removed the file from your folio."
    assert_response :redirect
  end
    
  def test_shall_empty_entire_folio
    login_as :quentin
    assets = assets_for(current_user)
    assets.map{|a| @request.session[:folio] << a.id}
    assert_equal assets.size, @request.session[:folio].size
    
    get :remove_all 
    assert_equal assets.size, @request.session[:folio].size
    assert_response :redirect
    
    post :remove_all
    assert_equal 0, @request.session[:folio].size
    assert_response :redirect
  end
  
  def test_shall_zip_folio_for_download
    login_as :quentin
    assets = assets_for(current_user)
    assets.map{|a| @request.session[:folio] << a.id}
    assert_equal assets.size, @request.session[:folio].size
    assert @request.session[:folio].size > 0
    post :zip
    assert File.file?(assigns(:zip_file)), "Zip file should have been created."
    #clean up the newly created zip files.
    File.delete assigns(:zip_file)
    assert !File.file?(assigns(:zip_file)), "Zip file should have been deleted."
  end
  
  protected
  def add_item_for(user)
    #get the first unique asset to add to the folio
    assets_for( user ).map do |a|
      return @request.session[:folio] << a.id unless @request.session[:folio].include? a.id
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
