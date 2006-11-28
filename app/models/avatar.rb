# Schema as of Sun Nov 26 22:00:45 PST 2006 (schema version 2)
#
#  id                  :integer(11)   not null
#  content_type        :string(255)   
#  filename            :string(255)   
#  size                :integer(11)   
#  parent_id           :integer(11)   
#  thumbnail           :string(255)   
#  width               :integer(11)   
#  height              :integer(11)   
#  user_id             :integer(11)   
#  db_file_id          :integer(11)   
#

#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett & Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

class Avatar < ActiveRecord::Base
  belongs_to :user

  acts_as_attachment :content_type => :image, :resize_to => [100, 100]
  validates_as_attachment
  
  # Read from the model's attributes if it's available.
  def data
    read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
  end
end
