require File.dirname(__FILE__) + '/../test_helper'
require 'inbox_controller'

# Re-raise errors caught by the controller.
class InboxController; def rescue_action(e) raise e end; end

class InboxControllerTest < Test::Unit::TestCase
  fixtures :users, :profiles, :people, :collections, :feeds, :subscriptions, :memberships, :linkings
  def setup
    @controller = InboxController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_get_index
    login_as :quentin
    get :index
    assert_response :success
  end
  
  def test_shall_redirect_unless_logged_in
    get :index
    assert_redirected_to :controller=>'account',:action=>'login'
  end
  
  def test_shall_display_subscriber_feeds
    login_as :quentin
    get :index
    assert assigns(:feeds)
    assert !assigns(:current_user).feeds.empty?
  end
  
  def test_shall_edit_feed
    login_as :quentin
    cat = users(:quentin).categories[0]
    f = a_feed    
    
    assert_no_difference Feed, :count do
      # Cannot add or edit on get  
      get :edit_feed, :feed=>{:url=>"http://#{@request.host_with_port}/feed/category/#{cat.id}",:name=>cat.name}
   
      # Edit an existing feed
      new_attributes = {:url=>"http://#{@request.host_with_port}/feed/category/#{cat.id}",:name=>cat.name}
      post :edit_feed,:id=>f.id, :feed=>new_attributes
      assert_response :success
      
      new_attributes.each_pair do|k,v|
        assert_equal assigns(:feed)[k], v
      end
    end 
  end
  
  def test_create_new_feed
    login_as :quentin
    cat = users(:quentin).categories[0]
    
    assert_difference Feed, :count do
      post :edit_feed, :feed=>{:url=>"http://#{@request.host_with_port}/feed/category/#{cat.id}",:name=>cat.name}
      assert_response :success
      assert assigns(:current_user).feeds(true).map{|feed| feed.name }.include?(cat.name)
    end
    
    #Do not add the same feed twice
    assert_no_difference Feed, :count do
      post :edit_feed, :feed=>{:url=>"http://#{@request.host_with_port}/feed/category/#{cat.id}",:name=>cat.name}
      assert_response :success
      assert assigns(:current_user).feeds(true).map{|feed| feed.name }.include?(cat.name)
    end
    
  end
  
  def test_shall_subscribe_to_feed
    login_as :quentin
    u = users(:quentin)
    @category = u.categories[0]
    feed_url = CGI.escape("http://localhost:3000/feed/category/#{@category.id}" )
    assert_changed u.feeds, :size do
      post :subscribe_feed, :url=>feed_url,:name=>@category.id
      assert_redirected_to :controller=>'inbox', :action=>'inbox'
      assert assigns(:flash)[:notice]
    end
  end
  
  def test_shall_not_subscribe_to_same_feed_twice
    login_as :quentin
    u = users(:quentin)
    f = u.feeds[0]
    assert_no_difference Feed, :count do
      post :subscribe_feed, :local_path=>f.local_path, :name=>f.name
      assert_redirected_to :controller=>'inbox', :action=>'inbox'
    end
  end
  
  def test_shall_read_feed
    login_as :quentin
    u = users(:quentin)
    f = u.feeds[0]
    get :read_feed, :id=>f.id
    assert assigns(:messages)
    assert_response :success
    assert assigns(:flash).empty?    
  end
  
  def test_shall_redirect_on_bad_feed
    login_as :quentin
    get :read_feed, :id=>'-212121' # Bad Feed id.
    assert_response :redirect
    assert !assigns(:flash)[:error].empty?
  end
  
  def test_shall_unsubscribe_feed
    login_as :quentin
    u = users(:quentin)
    # Do not unsubscribe on get requests
    assert_unchanged u.feeds, :size do
      get :unsubscribe_feed, :id=>u.feeds[0].id
      assert_redirected_to :controller=>'inbox', :action=>'inbox'
    end

    # Do not unsubscribe without an ID
    assert_unchanged u.feeds, :size do
      post :unsubscribe_feed
      assert_redirected_to :controller=>'inbox', :action=>'inbox'
      assert !assigns(:flash)[:error].empty?
    end
    
    # OK to unsubscribe
    assert_changed u.feeds ,:size do
      post :unsubscribe_feed, :id=>u.feeds[0].id
      assert_redirected_to :controller=>'inbox', :action=>'inbox'
    end
  end
  
end
