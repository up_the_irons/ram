class AddSettingPreferenceColumn < ActiveRecord::Migration
  def self.up
    add_column :settings, :preferences, :text, :default => ''
  end

  def self.down
    remove_column :settings, :preferences
  end
end
