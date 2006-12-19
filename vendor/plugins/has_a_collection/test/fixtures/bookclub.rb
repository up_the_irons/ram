class Bookclub < ActiveRecord::Base
  has_collection :of => %w(books), :table_name => 'members', :class_column => "member", :association_column => "offering"
  is_collected :by=>["readers"], :table_name => 'members', :class_column => "offering", :association_column => "member"
  
  def reader_before_add(record = nil)
    self.update_attribute(:subscribers_count, self.subscribers_count += 1)
  end
  
  def reader_after_add(record = nil)
    self.update_attribute(:recent_subscriber_id, record.id)
  end
  
  def reader_before_remove(record = nil)
    self.update_attribute(:last_subscriber_to_cancel_id, record.id)
  end

  def book_before_add(record = nil)
    self.update_attribute(:offerings_count, self.offerings_count += 1)
  end
  
  def book_after_remove(record = nil)
    self.update_attribute(:last_months_offering_id, record.id)
  end
end