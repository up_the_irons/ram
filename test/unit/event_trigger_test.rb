require File.dirname(__FILE__) + '/../test_helper'

class EventTriggerTest < Test::Unit::TestCase
  fixtures :event_triggers, :users

  def test_subscribers_of
    users = EventTrigger.subscribers_of(:user_signup)

    assert_equal 2, users.size
    assert users.include?(users(:quentin))
    assert users.include?(users(:user_5))
  end
end
