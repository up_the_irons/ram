class CreateEventSubscriptions < ActiveRecord::Migration
  def self.up
    table_name = 'event_subscriptions'

    create_table table_name do |t|
      t.column :user_id,          :integer
      t.column :event_trigger_id, :integer
    end

    execute "ALTER TABLE #{table_name} ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
    execute "ALTER TABLE #{table_name} ADD FOREIGN KEY (event_trigger_id) REFERENCES event_triggers(id) ON DELETE CASCADE"
  end

  def self.down
    drop_table :event_subscriptions
  end
end
