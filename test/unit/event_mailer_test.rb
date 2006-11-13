require File.dirname(__FILE__) + '/../test_helper'
require 'event_mailer'

class EventMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  # Keep around for reference, but we won't use it currently
  def old_test_notification
    @expected.subject = 'EventMailer#notification'
    @expected.body    = read_fixture('notification')
    @expected.date    = Time.now

    assert_equal @expected.encoded, EventMailer.create_notification(@expected.date).encoded
  end

  def test_truth
    assert true
  end

  private

  def read_fixture(action)
    IO.readlines("#{FIXTURES_PATH}/event_mailer/#{action}")
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
