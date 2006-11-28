module IncludedTests; end

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/admin_controller_test/group_methods_test'
require File.dirname(__FILE__) + '/admin_controller_test/category_methods_test'
require File.dirname(__FILE__) + '/admin_controller_test/user_methods_test'
require File.dirname(__FILE__) + '/admin_controller_test/event_subscriptions_test'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :collections, :attachments, :db_files, :users, :linkings, :memberships,:changes, :profiles, :people, :settings

  include IncludedTests::UserMethodsTest
  include IncludedTests::GroupMethodsTest
  include IncludedTests::CategoryMethodsTest
  include IncludedTests::EventSubscriptionsTest
  
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @existing_category_id = 8
    @user_with_access_to_all_categories = 1
    @user_with_access_to_no_categories  = 7
    login_as :administrator # Has admin_rights
  end
  
  def test_shall_redirect_to_index_when_a_non_admin_accesses_controller
    login_as :user_without_group_memberships
    get :index
    assert_redirected_to :controller=>'inbox'
  end
  
  def test_shall_allow_admin_access
    get :index
    assert_redirected_to :action=>'dashboard'
  end
  
  def test_track_model_changes
    login_as :administrator
    @group    = a_group
    @category = a_category({:parent_id=>@existing_category_id})
    @user     = create_user
    @article  = an_article({:category_id=>@existing_category_id})
    @asset    = an_asset({:category_id=>@existing_category_id})
    [Group,Category,Asset,User,Article].each do |model|
      obj = instance_variable_get("@#{model.to_s.downcase}")
      assert_equal 1, obj.changes.size
      assert_equal obj.changes[0].record_id.to_i, obj.id, "Expecting record for #{model}"
    end    
  end
  
  def test_category_change_log_tracks_children_changes
    login_as :administrator
    user = users(:administrator)
    category = user.categories[0]
    assert_difference category.changes, :count, 2 do
      @a = an_asset({:user_id => user.id,:category_id => category.id})
      @art = an_article({:user_id => user.id,:category_id => category.id})
      assert @a.valid?
    end
    
    assert_equal(category.changes[0].event, "Added #{@a.name}")
    assert_equal(category.changes[1].event, "Added #{@art.name}")
    assert_difference category.changes, :count, 2 do
      @a.destroy
      @art.destroy
    end
    
    category.changes(true)

    assert_equal(category.changes[2].event, "Removed #{@a.name}")
    assert_equal(category.changes[3].event, "Removed #{@art.name}")
  end
  
  def test_shall_make_site_configuration_changes
    login_as :administrator
    settings = Setting.find(:first)
    @props = {:application_name => 'foo bar baz',:filesize_limit => 10000*1024,:admin_group_id =>1}  
    # Cannot make changes on get
    get :settings, :settings => @props
    @props.each_pair do | k, v |
      assert assigns(:settings)[k] != @props[k], "\"#{@props[k]}\" should not equal \"#{assigns(:settings)[k]}\""
    end
    
    # Make changes with this post
    post :settings, :settings => @props
    @props.each_pair do | k, v |
      assert_equal @props[k], assigns(:settings)[k] 
    end
    
    #rollback changes to settings to ensure the global variable doesn't change for the rest of the tests.  
    post :settings, :settings => {:application_name => settings.application_name, :admin_group_id => settings.admin_group_id, :filesize_limit => settings.filesize_limit}
    @props.each_pair do | k, v |
      assert_equal settings[k], assigns(:settings)[k] 
    end
  end
    
end
