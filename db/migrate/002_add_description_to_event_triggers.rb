class AddDescriptionToEventTriggers < ActiveRecord::Migration
  def self.up
    add_column :event_triggers, :description, :text, :default => '', :null => false

    r = EventTrigger.find_by_code('UserSignup')
    r.description = 'Fires when a new user is registered'
    r.save

    r = EventTrigger.find_by_code('UserDeleted')
    r.description = 'Fires when a user is deleted'
    r.save

    r = EventTrigger.find_by_code('UserSuspended')
    r.description = 'Fires when a user is suspended (currently, nothing hooks into this)'
    r.save

    r = EventTrigger.find_by_code('GroupModification')
    r.description = 'Fires whenever a Group is modified (currently, nothing hooks into this)'
    r.save
  end

  def self.down
    remove_column :event_triggers, :description
  end
end
