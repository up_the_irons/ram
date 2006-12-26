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

  begin
    require 'RMagick'
    acts_as_attachment :content_type => :image, :resize_to => [100, 100]
  rescue LoadError
    # Failed to load RMagick do not create avatar image
  end
  
  validates_as_attachment
  
  # Read from the model's attributes if it's available.
  def data
    read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
  end
end
