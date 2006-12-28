class AddDefaultPreferencesValues < ActiveRecord::Migration
  def self.up
    Setting.transaction do
      Setting.find(:all).each do |s| 
        s.preferences = {:rmagick => true}
        s.save!
      end
    end
  end

  def self.down
  end
end
