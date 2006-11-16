require File.dirname(__FILE__) + '/../test_helper'

class EventSubscriptionTest < Test::Unit::TestCase
  fixtures :event_subscriptions, :event_triggers, :users

  def test_belongs_to_user
    e = event_subscriptions(:administrator_1)
    u = e.user
    u2 = users(:administrator)

    assert_equal u, u2
  end

  def test_belongs_to_event_trigger
    t = event_subscriptions(:administrator_1).event_trigger
    t2 = event_triggers(:user_signup)

    assert_equal t, t2

    t = event_subscriptions(:administrator_2).event_trigger
    t2 = event_triggers(:user_suspended)

    assert_equal t, t2
  end

  def test_existance_of_default_subscriptions_for_admin_user
    admin = User.find(1) # Assumes User with ID of 1 is the admin user

    EventTrigger.default_codes.each do |code|
      assert EventSubscription.find_by_user_id_and_event_trigger_id(admin.id, EventTrigger.find_by_code(code).id)
    end
  end
end
