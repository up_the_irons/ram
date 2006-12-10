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
