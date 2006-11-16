require File.dirname(__FILE__) + '/../test_helper'

class EventTriggerTest < Test::Unit::TestCase
  fixtures :event_triggers, :users

  def test_subscribers_of
    users = EventTrigger.subscribers_of(:user_signup)
    assert_equal 2, users.size
    assert users.include?(users(:administrator))
    assert users.include?(users(:normal_user))
  end

  def test_existance_of_default_triggers
    @default_codes = %w(UserSignup UserDeleted UserSuspended GroupModification)

    @default_codes.each do |code|
      assert EventTrigger.find_by_code(code)
    end
  end
end
