class GroupObserver < ActiveRecord::Observer
  def after_create(group)
    
   #TODO: Create an event trigger like the user model does.
   
   #grant all the admins access to this new group (FIXME: it feels brittle to hardcode 'Administrators')
   Group.find_by_name('Administrators').users.each{|m| group.users << m }
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
