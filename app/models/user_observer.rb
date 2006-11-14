#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

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
  end
end
