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
    assert :success
    assert a = assigns['assets']
    assert_equal 0, a.size

    post :all, :query => 'game'
    assert :success
    assert cats = assigns['cats']
    assert_equal 2, cats.size

    res = cats.map { |o| o.name }
    assert res.include?('Video Game Database')
    assert res.include?('Games')

    post :all, :query => 'only'
    assert :success
    assert groups = assigns['groups']
    assert_equal 1, groups.size
    assert_equal 'Atari', groups[0].name 
  end

  def test_search_all_for_user2
    login_as :quentin # admin
    post :all, :query => 'nes'
    assert :success
    assert a = assigns['assets']
    assert_equal 1, a.size

    assert cats = assigns['cats']
    assert_equal 1, cats.size

    assert_equal 'Sega Genesis', cats[0].name

    assert groups = assigns['groups']
    assert_equal 0, groups.size

    post :all, :query => 'a'
    assert :success
    assert groups = assigns['groups']
    assert_equal 2, groups.size
    res = groups.map { |o| o.name }
    assert res.include?("Administrators")
    assert res.include?("Atari")
  end

  def test_search_all_for_user3
    login_as :user_4

    post :all, :query => '2600'
    assert :success
    assert a = assigns['assets']
    assert c = assigns['cats']

    assert_equal 3, a.size
    res = a.map { |o| o.name }
    res.include?("atari-xe-large.jpg")
    res.include?("atari-games-stacked.jpg")
    res.include?("atari2600_console01.jpg")

    assert_equal 1, c.size
    res = c.map { |o| o.name }
    res.include?('Atari 2600')

    post :all, :query => 'carts'
    assert :success
    assert a = assigns['assets']
    assert c = assigns['cats']
    assert g = assigns['groups']

    assert_equal 1, a.size
    assert_equal 0, c.size
    assert_equal 0, g.size
    res = a.map { |o| o.name }
    res.include?("atari-games-stacked.jpg")

    post :all, :query => 'logo'
    assert :success
    assert a = assigns['assets']
    assert c = assigns['cats']
    assert g = assigns['groups']

    assert_equal 1, a.size
    assert_equal 0, c.size
    assert_equal 0, g.size
    res = a.map { |o| o.name }
    res.include?("rails.png")
  end
end
