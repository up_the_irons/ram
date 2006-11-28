# Schema as of Sun Nov 26 22:00:45 PST 2006 (schema version 2)
#
#  id                  :integer(11)   not null
#  controller          :string(128)   default(), not null
#  action              :string(128)   default(), not null
#  num_per_page        :integer(11)   default(10), not null
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

class PagingTable < ActiveRecord::Base
  set_table_name 'paging'
end
