class AddFeedsAndSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.column :subscriber_id      , :integer
      t.column :subscriber_type    , :string
      t.column :subscribed_to_id   , :integer
      t.column :subscribed_to_type , :string
      t.column :created_at         , :datetime
      t.column :updated_at         , :datetime
    end
    
    create_table :feeds do |t|
      t.column :url        , :string
      t.column :name       , :string
      t.column :created_at , :datetime
      t.column :updated_at , :datetime
    end
  end

  def self.down
    drop_table :subscribers
    drop_table :feeds
  end
end
