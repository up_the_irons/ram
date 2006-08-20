class EventSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_trigger
end
