# Schema as of Sun Oct 22 21:28:20 PDT 2006 (schema version 19)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  event_trigger_id    :integer(11)   
#

class EventSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_trigger
end
