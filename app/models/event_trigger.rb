#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett, Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  code                :string(64)    
#

class EventTrigger < ActiveRecord::Base
  @@default_codes = %w(UserSignup UserDeleted UserSuspended GroupModification)
  cattr_reader :default_codes

  class <<self
    def subscribers_of(event)
      event = event.to_s.camelize

      res = EventSubscription.find_all_by_event_trigger_id(find_by_code(event).id)
      res.map { |o| o.user }
    end
  end
end
