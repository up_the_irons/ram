class Subscription < ActiveRecord::Base
  belongs_to :subscriber, :polymorphic=> true, :foreign_key=>'subscriber_id'
  belongs_to :subscribed_to, :polymorphic=> true, :foreign_key=>'subscribed_id'
  
  def before_save
    # breakpoint
  end
  
  validates_presence_of :subscriber_id, :subscriber_type, :subscribed_to_id, :subscribed_to_type
end