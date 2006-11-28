module IncludedTests::EventSubscriptionsTest
  def test_event_subscriptions
    # Should get list w/ all check boxes checked (4 triggers)
    get :event_subscriptions
    assert_response :success
    assert_template 'event_subscriptions'

    assert_equal 4, assigns['subscribed_to'].size

    # Check only 2 boxes and verify we're now only subscribed to 2 events
    post :event_subscriptions, :event_subscriptions => ['UserSignup', 'GroupModification']
    assert_response :success
    assert_template 'event_subscriptions'

    assert_equal 2, assigns['subscribed_to'].size
  end
end
