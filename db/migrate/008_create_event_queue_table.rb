class CreateEventQueueTable < ActiveRecord::Migration
  def self.up
    table_name = 'events'

    create_table table_name do |t|
      t.column :sender_id,    :integer
      t.column :recipient_id, :integer
      t.column :subject,      :text
      t.column :msg_body,     :text
      t.column :created_at,   :datetime
      t.column :read_at,      :datetime
    end

    execute "ALTER TABLE #{table_name} ADD FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE"
    execute "ALTER TABLE #{table_name} ADD FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE"
  end

  def self.down
    drop_table :events
  end
end
