class Avatar < ActiveRecord::Base
  belongs_to :user
  acts_as_attachment :content_type => :image, :resize_to => [50,50]
  validates_as_attachment
  
  # Read from the model's attributes if it's available.
  def data
    read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
  end
end
