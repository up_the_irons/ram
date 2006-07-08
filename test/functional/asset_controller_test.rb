require File.dirname(__FILE__) + '/../test_helper'
require 'asset_controller'

# Re-raise errors caught by the controller.
class AssetController; def rescue_action(e) raise e end; end

class AssetControllerTest < Test::Unit::TestCase
  fixtures :collections, :linkings, :attachments, :db_files, :users, :memberships

  def setup
    @controller = AssetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

 #todo not sure this needs to be tested since it is just the base of the STI
 
 def test_assigned_and_remaining_groups
   
 end
 
 def test_remove_from_group
   
 end
 
 def test_add_to_group
 
 end
 
 def test_shall_not_remove_from_group_on_get
   
 end
 
 def test_shall_not_add_group_from_get
 
 end
 
 def test_destroy
 
 end
 
 def test_create
 
 end
 
 def test_update
 
 end
 
 def test_shall_not_add_the_same_group_twice
 
 end
 
 def test_shall_not_upload_the_same_asset_twice_to_identical_categories
   
 end
 
 def test_shall_only_present_select_options_from_unassigned_groups
   
 end
 
 def test_shall_prevent_users_from_uploading_to_restricted_groups
 
 end
 
end
