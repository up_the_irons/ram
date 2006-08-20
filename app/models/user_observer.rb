class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserNotifier.deliver_signup_notification(user)

    EventTrigger.subscribers_of(:user_signup).each do |u|
      Event.create(:recipient_id => u.id, 
                   :subject      => "User '#{user.login}' created", 
                   :msg_body     => "User '#{user.login}' created. You should add this user to one or more groups.")
    end
  end

  def after_save(user)
    # UserNotifier.deliver_activation(user) if user.recently_activated?
    #
    # recently_activated?() does not seem to exist. 
    # This observer was not even running until now when I found this, so when I activated it in environment.rb
    # I got errors. So I commented out the above line.
    # Mark, you didn't test this did you? :)
  end
end
