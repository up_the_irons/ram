class CreateDefaultAdminUser < ActiveRecord::Migration
  def self.up
    u = User.create(:login => 'admin', :password => 'admin', :password_confirmation => 'admin', :email => 'admin@localhost', :state => 2, :role => 1)

    # Subscribe the admin user to every event trigger
    EventTrigger.default_codes.each do |code|
      e = EventSubscription.new
      e.user = u
      e.event_trigger = EventTrigger.find_by_code(code)
      e.save!
    end

    u.person.first_name = "Administrator"
    u.save
  end

  def self.down
    User.find_by_login('admin').destroy
  end
end
