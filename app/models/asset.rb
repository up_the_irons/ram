# Schema as of Sat Aug 26 15:14:40 PDT 2006 (schema version 12)
#
#  id                  :integer(11)   not null
#  content_type        :string(100)   
#  filename            :string(255)   
#  size                :integer(11)   
#  db_file_id          :integer(11)   
#  path                :string(255)   
#  parent_id           :integer(11)   
#  thumbnail           :string(255)   
#  width               :integer(11)   
#  height              :integer(11)   
#  image_format        :string(255)   
#  aspect_ratio        :float         
#  depth               :integer(11)   
#  colors              :integer(11)   
#  colorspace          :string(255)   
#  resolution          :string(255)   
#  description         :text          
#  user_id             :integer(11)   
#  created_on          :datetime      
#  updated_on          :datetime      
#  type                :string(255)   
#

#class Asset < Attachment
class Asset < ActiveRecord::Base  
   acts_as_attachment
  
   set_table_name "attachments"
   # has_and_belongs_to_many :access_contexts, :table_name=>'access_contacts_attachments', :foreign_key=>'access_context'
   #has_and_belongs_to_many :access_contexts,
   #                         :join_table=>'access_contexts_attachments', 
   #                         :foreign_key=>'attachment_id', 
   #                        :class_name=>"AccessContext", 
   #                        :table_name=>"attachments"
   
   has_many :linkings, :as =>:linkable,:dependent => :destroy
   has_many :groups, :through=> :linkings do
    def << (group)
      return if @owner.groups.include?group
      l = Linking.create(
          :linkable_id => @owner.id,
          :linkable_type => "Asset",
          :group_id => group.id
  	    )
  	  l.errors.each_full { |msg| puts msg } unless l.save 
    end
    
   end
   
   has_many :categories, :through=> :linkings do
    def << (category)
      return if @owner.categories.include?category
      l = Linking.create(
          :linkable_id => @owner.id,
          :linkable_type => "Asset",
          :group_id => category.id
  	    )
  	  l.errors.each_full { |msg| puts msg } unless l.save
    end
    
   end
   belongs_to :user
   #TODO: make this validation work
   #validates_uniqueness_of :filename, :scope => [:groups]
   
   class << self    
     def find_with_data(quantity, options = {})
       find quantity, options.merge(:select => 'attachments.*, db_files.data', :joins => 'LEFT OUTER JOIN db_files ON attachments.db_file_id = db_files.id')
     end

     def find_by_full_path(full_path)
       pieces   = full_path.split '/'
       filename = pieces.pop
       path     = pieces.join '/'
       find_with_data :first, :conditions => ['path = ? and filename = ?', path, filename]
     end
   end
   
   def name
     filename
   end

   # Read from the model's attributes if it's available.
   def data
     read_attribute(:data) || write_attribute(:data, (db_file_id ? db_file.data : nil))
   end

   # set the model's data attribute and attachment_data
   def data=(value)
     self.attachment_data = write_attribute(:data, value)
   end

   def full_path
     (path && filename) ? File.join(path, filename) : (filename || path)
   end
   
   private
   
end

