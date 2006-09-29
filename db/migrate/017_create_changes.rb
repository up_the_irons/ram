class CreateChanges < ActiveRecord::Migration
  def self.up
    create_table :changes do |t|
      t.column :record_id, :integer
      t.column :record_type, :string
      t.column :event, :string
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :changes
  end
end
