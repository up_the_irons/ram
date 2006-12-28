class AddDefaultPreferencesValues < ActiveRecord::Migration
  def self.up
    Setting.find(:all).each{|s| s.update_attribute('preferences', {:rmagick? => true})}
  end

  def self.down
  end
end
