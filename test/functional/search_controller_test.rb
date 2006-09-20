require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  fixtures :users, :linkings, :attachments, :collections, :memberships

  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_search_all_for_user
    login_as :user_4 # nolan bushnell

    post :all, :id => 'nes'
    assert :success
    assert a = assigns['assets']
    assert_equal 0, a.size

    post :all, :id => 'game'
    assert :success
    assert cats = assigns['cats']
    assert_equal 2, cats.size

    res = cats.map { |o| o.name }
    assert res.include?('Video Game Database')
    assert res.include?('Games')

    post :all, :id => 'only'
    assert :success
    assert groups = assigns['groups']
    assert_equal 1, groups.size
    assert_equal 'Atari', groups[0].name 
  end

  def test_search_all_for_user2
    login_as :quentin # admin
    post :all, :id => 'nes'
    assert :success
    assert a = assigns['assets']
    assert_equal 1, a.size

    assert cats = assigns['cats']
    assert_equal 1, cats.size

    assert_equal 'Sega Genesis', cats[0].name

    assert groups = assigns['groups']
    assert_equal 0, groups.size

    post :all, :id => 'a'
    assert :success
    assert groups = assigns['groups']
    assert_equal 2, groups.size
    res = groups.map { |o| o.name }
    assert res.include?("Administrators")
    assert res.include?("Atari")
  end
  
  def test_search_returns_no_results
    login_as :quentin
    post :all, :id => '-43gfffff4234f4fc34c3cf3333f'
    assert :success
    assert_equal assigns(:flash)[:notice], "Your search returned no results."
  end
end
