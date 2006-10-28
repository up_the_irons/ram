class Subscription < ActiveRecord::Base
  #belongs_to :subscriber, :foreign_key => "subscriber_id", :polymorphic =>true
  belongs_to :subscriber, :polymorphic=> true, :foreign_key=>'subscriber_id'
  belongs_to :subscribed_to, :polymorphic=> true, :foreign_key=>'subscribed_id'
end