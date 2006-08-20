require File.dirname(__FILE__) + '/../test_helper'

class EventTest < Test::Unit::TestCase
  fixtures :events, :users

  def setup
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  def test_notification_on_create
    recipient_id = users(:quentin).id
    subject      = 'New Event Notification'
    msg_body     = 'In UR Eventz, Eatin URR Queueueuez'

    Event.create(:recipient_id => recipient_id, :subject => subject, :msg_body => msg_body, :created_at => Time.now)

    assert_equal 1, @emails.size
    email = @emails.first
    assert_match(/RAM Event Notification/, email.subject)
    assert_match(/#{msg_body}/, email.body)
    assert_equal User.find(recipient_id).email, email.to[0]
    assert_equal 1, email.to.size
  end

  def test_timestamp
    e = Event.create(:recipient_id => users(:quentin).id)

    assert_not_nil e.created_at
    assert e.created_at <= Time.now
  end
end
