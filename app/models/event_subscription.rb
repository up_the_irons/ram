# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  event_trigger_id    :integer(11)   
#

class EventSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_trigger
end
