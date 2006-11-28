class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings, :force => true do |t|
       t.column :application_name, :string
       t.column :admin_group_id, :integer
       t.column :filesize_limit, :integer
    end
    # Assign default settings for the applicaation.
    limit = 50000 * 1024 # Around 50 megs
    s = Setting.create({:application_name => 'RAM', :admin_group_id => Group.find_by_name('Administrators').id, :filesize_limit => limit})
  end

  def self.down
    drop_table :settings
  end
end
