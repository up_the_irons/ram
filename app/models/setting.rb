# Schema as of Sun Nov 26 22:00:45 PST 2006 (schema version 2)
#
#  id                  :integer(11)   not null
#  application_name    :string(255)   
#  admin_group_id      :integer(11)   
#  filesize_limit      :integer(11)   
#

class Setting < ActiveRecord::Base
  validates_presence_of :application_name, :admin_group_id, :filesize_limit
  validates_numericality_of :admin_group_id, :filesize_limit
  @@max_limit = 100000 * 1024
  @@min_limit = 1000 * 1024
  def before_save
    errors.add :filesize_limit, "Filesize limit must be at least one megabyte and no more than 100 megabytes." and return false if filesize_limit  > @@max_limit  || filesize_limit < @@min_limit
    
    begin
      @group = Group.find admin_group_id
    rescue
      errors.add :admin_group_id, "This group is invalid" and return false unless @group
    end 
    errors.add :admin_group_id, "The admin group needs to have at least one member" and return false if @group.users.empty?
    errors.add :admin_group_id, "This group could not be locked to prevent deletion" and return false unless @group.update_attribute(:permanent, true)
  end
end
