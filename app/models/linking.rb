# Schema as of Fri Oct 27 20:31:51 PDT 2006 (schema version 22)
#
#  id                  :integer(11)   not null
#  user_id             :integer(11)   
#  category_id         :integer(11)   
#  group_id            :integer(11)   
#  linkable_id         :integer(11)   
#  linkable_type       :string(255)   
#  created_on          :datetime      
#  updated_on          :datetime      
#


class Linking < ActiveRecord::Base
  belongs_to :user,     :foreign_key => 'user_id' 
  belongs_to :group,    :foreign_key => 'group_id',    :class_name => 'Group'
  belongs_to :category, :foreign_key => 'category_id', :class_name => 'Category'
  belongs_to :asset,    :foreign_key => 'linkable_id', :class_name => 'Asset'
  belongs_to :article,  :foreign_key => 'linkable_id', :class_name => 'Article'
  belongs_to :linkable, :polymorphic => true
  
  def join(opts)
      linking = {:user_id=>nil,:category_id=>nil,:group_id=>nil,:linkable_id=>nil,:linkable_type=>nil}.merge(opts)
      if self.new_record?
        self.create(linking)
      else
        self.attributes.merge(opts)
        self.save!
      end
  end
  
  def break(linking)
  
  end
  
  def break_all(linking)
  
  end
  
  validates_uniqueness_of :linkable_id, :scope => [:group_id,:category_id,:linkable_type], :message=>'already added.'
end
