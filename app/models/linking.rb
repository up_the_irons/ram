# Schema as of Sat Aug 26 15:14:40 PDT 2006 (schema version 12)
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
  #belongs_to :group
  #belongs_to :category
  #belongs_to :user
  
  belongs_to :user, :foreign_key=>'user_id'

        belongs_to :group, :class_name=>"Group",
                     :foreign_key=>"group_id"

        belongs_to :category, :class_name=>"Category",
                        :foreign_key=>"category_id"
                        
  belongs_to :linkable, :polymorphic =>true
  belongs_to :asset,    :class_name =>'Asset', :foreign_key =>:linkable_id
  
  validates_uniqueness_of :linkable_id, :scope => [:group_id,:category_id], :message=>'Asset already added.'
  #validates_uniqueness_of :category_id, :scope => [:group_id]
  #validates_uniqueness_of :group_id   , :scope => [:category_id]   
  def validate 
    # TODO: in the cases where a user user only supplies a partial record (category but no group or vice versa) 
    # query the db to determine that an existing partial record does not actually complete this new record and 
    # therefore defeat the need to create this record in the first place.
    
    #errors.add_to_base('existing partial record was found so no new record was created.')
  end 
end
