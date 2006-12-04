# Schema as of Sun Nov 26 22:00:45 PST 2006 (schema version 2)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  first_name          :string(200)   default()
#  last_name           :string(200)   default()
#  gender              :integer(11)   default(0), not null
#  date_of_birth       :date          
#  created_on          :datetime      
#  updated_on          :datetime      
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

class Person < ActiveRecord::Base
  belongs_to :user

  GENDERS = [
            ['Unspecified', 0],
            ['Male', 1],
            ['Female', 2]
            ].freeze

  def full_name
    first_name + ' ' + last_name
  end

  def name
    first_name + ' ' + last_name      
  end
end
