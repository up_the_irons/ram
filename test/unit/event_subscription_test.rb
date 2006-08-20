require File.dirname(__FILE__) + '/../test_helper'

class EventSubscriptionTest < Test::Unit::TestCase
  fixtures :event_subscriptions, :event_triggers, :users

  def test_belongs_to_user
    e = event_subscriptions(:quentin_1)
    u = e.user
    u2 = users(:quentin)

    assert_equal u, u2
  end

  def test_belongs_to_event_trigger
    t = event_subscriptions(:quentin_1).event_trigger
    t2 = event_triggers(:user_signup)

    assert_equal t, t2

    t = event_subscriptions(:quentin_2).event_trigger
    t2 = event_triggers(:user_suspended)

    assert_equal t, t2
  end
end
