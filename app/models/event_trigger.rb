class EventTrigger < ActiveRecord::Base
  class <<self
    def subscribers_of(event)
      event = event.to_s.camelize

      res = EventSubscription.find_all_by_event_trigger_id(find_by_code(event).id)
      res.map { |o| o.user }
    end
  end
end
