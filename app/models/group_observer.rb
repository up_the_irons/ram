class GroupObserver < ActiveRecord::Observer
  def after_create(group)
    
   #TODO: Create an event trigger like the user model does.
   #Group.find_by_name(ADMIN_GROUP).users.each{|m| group.users << m }
  end

  def after_save(group)
    #Group.find_by_name(ADMIN_GROUP).users.each{|m| group.users << m }
  end
end
