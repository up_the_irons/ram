#--
# $Id: profile.rb 1038 2006-11-28 17:54:16Z mark $
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class Setting < ActiveRecord::Base
  validates_presence_of :application_name, :admin_group_id, :filesize_limit
  validates_numericality_of :admin_group_id, :filesize_limit
  serialize :preferences
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
