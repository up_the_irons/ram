# Schema as of Sun Oct 22 21:28:20 PDT 2006 (schema version 19)
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
