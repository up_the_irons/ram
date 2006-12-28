class AddDefaultPreferencesValues < ActiveRecord::Migration
  def self.up
   # prefs = {:rmagick => true}
   # change_column :settings, :preferences, :text
   # say_with_time "Updating settings..." do
   # # Setting.transaction do
   #     Setting.find(:all).each do |s| 
   #       s.application_name = "foo"
   #       s.preferences = {"rmagick" => true}
   #       say_with_time "#{s.to_yaml} saved." do
   #         s.save!
   #       end
   #     end
   #  # end
   # end
  end

  def self.down
  end
end
