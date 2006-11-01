class CreateDefaultEventsAndSubscriptions < ActiveRecord::Migration
  # These are just the new codes not already handled by previous migrations (not to be confused with EventTrigger.default_codes)
  @@default_codes = %w(UserDeleted UserSuspended GroupModification)

  def self.up
    @@default_codes.each do |code|
      EventTrigger.create(:code => code)
    end
  end

  def self.down
    conditions = @@default_codes.map { |code| "code = '#{code}'" }.join(" OR ")

    EventTrigger.delete_all(conditions)
  end
end
