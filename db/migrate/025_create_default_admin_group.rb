class CreateDefaultAdminGroup < ActiveRecord::Migration
  def self.up
    g = Group.create(:name => 'Administrators', 
                     :description => "Admins have access to all categories", 
                     :public => 1,
                     :user_id => 1, 
                     :state_id => 1, 
                     :permanent => true)

    g.users << User.find_by_login('admin')
  end

  def self.down
    Group.find_by_name('Administrators').destroy
  end
end
