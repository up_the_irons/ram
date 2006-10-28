# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
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
