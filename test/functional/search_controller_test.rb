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

    post :all, :query => 'nes'
    assert a = assigns['assets']
    assert_equal 0, a.size

    post :all, :query => 'game'
    assert cats = assigns['cats']
    assert_equal 2, cats.size

    res = cats.map { |o| o.name }
    assert res.include?('Video Game Database')
    assert res.include?('Games')
  end

  def test_search_all_for_user2
    login_as :quentin # admin
    post :all, :query => 'nes'
    assert a = assigns['assets']
    assert_equal 1, a.size

    assert cats = assigns['cats']
    assert_equal 1, cats.size

    assert_equal 'Sega Genesis', cats[0].name
  end
end
