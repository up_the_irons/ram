class CreateEventTriggers < ActiveRecord::Migration
  def self.up
    create_table :event_triggers do |t|
      t.column :code, :string, :limit => 64
    end

    add_index(:event_triggers, :code, :unique => true)

    EventTrigger.create(:code => 'UserSignup')
  end

  def self.down
    drop_table :event_triggers
  end
end
