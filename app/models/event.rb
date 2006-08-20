class Event < ActiveRecord::Base
  def after_create
    EventMailer.deliver_notification(User.find(recipient_id).email, self)
  end

  class <<self
    # Timestamp new Events automatically
    def create(attributes = nil)
      super({ :created_at => Time.now }.merge(attributes ? attributes : {}))
    end
  end
end
