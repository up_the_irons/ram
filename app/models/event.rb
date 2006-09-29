# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
#
#  id                  :integer(11)   not null
#  sender_id           :integer(11)   
#  recipient_id        :integer(11)   
#  subject             :text          
#  msg_body            :text          
#  created_at          :datetime      
#  read_at             :datetime      
#

class Event < ActiveRecord::Base
  def after_create
    EventMailer.deliver_notification(User.find(recipient_id).email, self)
  end
  
  def body
    msg_body
  end

  class <<self
    # Timestamp new Events automatically
    
    # Doesn't ActiveRecord do this automagically?
    def create(attributes = nil)
      super({ :created_at => Time.now }.merge(attributes ? attributes : {}))
    end
  end
end
