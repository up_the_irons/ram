# Schema as of Sun Oct 22 21:28:20 PDT 2006 (schema version 19)
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

class Avatar < ActiveRecord::Base
  belongs_to :user
  acts_as_attachment :content_type => :image, :resize_to => [100,100]
  validates_as_attachment
  
  # Read from the model's attributes if it's available.
  def data
    read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
  end
end
