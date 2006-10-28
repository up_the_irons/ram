# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  controller          :string(128)   default(), not null
#  action              :string(128)   default(), not null
#  num_per_page        :integer(11)   default(10), not null
#

class PagingTable < ActiveRecord::Base
  set_table_name 'paging'
end
