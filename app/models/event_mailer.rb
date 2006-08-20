class EventMailer < ActionMailer::Base

  def notification(recipient_email, event)
    @subject    = "RAM Event Notification: #{event.subject}"
    @body       = { :event => event }
    @recipients = recipient_email
    @from       = ''
    @sent_on    = Time.now
    @headers    = {}
  end
end
