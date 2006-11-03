class UserNotifier < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://YOURSITE/account/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://YOURSITE/"
  end
  
  def reset_password(user,new_password)
    setup_email(user)
    @subject    += 'Your password has been reset'
    @body[:password]  = "Your new password is #{new_password}"
  end
  
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "ADMINEMAIL"
    @subject     = APP_NAME
    @sent_on     = Time.now
    @body[:user] = user
  end
end
