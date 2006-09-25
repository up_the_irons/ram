# Schema as of Sun Sep 24 21:27:08 PDT 2006 (schema version 16)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  event_trigger_id    :integer(11)   
#

class EventSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_trigger
end
