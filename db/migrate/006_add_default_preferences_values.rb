class AddDefaultPreferencesValues < ActiveRecord::Migration
  def self.up
    Setting.transaction do
       Setting.find(:all).each do |s| 
        s.preferences = {"rmagick" => true}
        s.save || raise("Save failed")
       end
    end
  end

  def self.down
  end
end