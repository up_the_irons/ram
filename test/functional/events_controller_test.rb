require File.dirname(__FILE__) + '/../test_helper'
require 'events_controller'

# Re-raise errors caught by the controller.
class EventsController; def rescue_action(e) raise e end; end

class EventsControllerTest < Test::Unit::TestCase
  fixtures :users, :events

  def setup
    @controller = EventsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_admins_only
    login_as :user_5

    get :list
    assert_redirected_to :controller => 'account', :action => 'index'
  end

  def test_admins_only_without_prior_login
    get :list
    assert_redirected_to ''
  end

  def test_list
    u = users(:quentin)

    login_as u.login

    get :list

    assert_response :success
    assert_nil flash[:notice]
    assert_not_nil e = assigns['events']

    e.each do |e|
      assert_equal u.id, e.recipient_id
    end
  end

  def test_delete
    u = users(:quentin)
    login_as u.login

    assert_difference Event, :count, -1 do
      xhr :get, :delete, :id => events(:quentin_msg_1_unread).id
      assert_response :success

      assert_rjs :replace_html, 'events_table'
    end
  end

  def test_delete_with_id_that_does_not_belong_to_user
    u = users(:quentin)
    login_as u.login

    assert_no_difference Event, :count do
      assert_raise(ActiveRecord::RecordNotFound) do
        xhr :get, :delete, :id => events(:another_msg).id
      end
    end
  end

  def test_show
    u = users(:quentin)
    login_as u.login

    id = events(:quentin_msg_1_unread).id
    xhr :get, :show, :id => id

    assert_rjs :toggle, "event_body_container_#{id}"
    assert_rjs :replace_html, "event_body_#{id}", events(:quentin_msg_1_unread).msg_body
  end
end
