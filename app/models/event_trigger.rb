# Schema as of Tue Sep 05 23:25:32 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  code                :string(64)    
#

class EventTrigger < ActiveRecord::Base
  class <<self
    def subscribers_of(event)
      event = event.to_s.camelize

      res = EventSubscription.find_all_by_event_trigger_id(find_by_code(event).id)
      res.map { |o| o.user }
    end
  end
end
