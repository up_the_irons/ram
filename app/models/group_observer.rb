#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class GroupObserver < ActiveRecord::Observer
  def after_create(group)
    EventTrigger.subscribers_of(:group_modification).each do |u|
      Event.create(:recipient_id => u.id,
                   :subject      => "Group '#{group.name}' has been created.",
                   :msg_body     => "Group '#{group.name}' has been created.  You may add one or more users to this group.")
    end
    add_admins_to group
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

  # This was set to "after_save", but that prevents a group from even being able to be created that doesn't belong to an admin.
  # It is fine to add them initally on new_records but there should be some way to remove them from the group if this is desired.
  def add_admins_to(group)
    # Admins get access to new groups automatically
    Group.find($application_settings.admin_group_id).users.each { |m| group.users << m }
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
