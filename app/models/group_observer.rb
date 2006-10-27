class GroupObserver < ActiveRecord::Observer
  def after_create(group)
    EventTrigger.subscribers_of(:group_modification).each do |u|
      Event.create(:recipient_id => u.id,
                   :subject      => "Group '#{group.name}' has been created.",
                   :msg_body     => "Group '#{group.name}' has been created.  You may add one or more users to this group.")
    end
  end

  def after_destroy(group)
    EventTrigger.subscribers_of(:group_modification).each do |u|
      Event.create(:recipient_id => u.id,
                   :subject      => "Group '#{group.name}' has been disbanned.",
                   :msg_body     => "Group '#{group.name}' has been disbanned.  Users belonging to this group may have access to less categories.")
    end

    group.users.each do |u|
      self.class.after_remove(group, u)
    end
  end

  def after_save(group)
    # Admins get access to new groups automatically
    Group.find_by_name(ADMIN_GROUP).users.each { |m| group.users << m }
  end

  class <<self
    # These callbacks can be triggered manually.  They do not automatically tie into the ActiveRecord lifecycle.
    # This is just a good spot to keep all callbacks in one place.

    def after_add(group, user)
      Event.create(:recipient_id => user.id,
                   :subject      => "You have been added to group '#{group.name}'",
                   :msg_body     => "You have been added to group '#{group.name}'.  You may have access to more categories.")
    end

    def after_remove(group, user)
      Event.create(:recipient_id => user.id,
                   :subject      => "You have been removed from group '#{group.name}'",
                   :msg_body     => "You have been removed from group '#{group.name}'.  You may have access to fewer categories.")
    end
  end
end
