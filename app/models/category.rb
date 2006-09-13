# Schema as of Tue Sep 05 23:25:32 PDT 2006 (schema version 15)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  description         :text          
#  public              :boolean(1)    default(true)
#  user_id             :integer(11)   
#  type                :string(255)   
#  state_id            :integer(11)   
#  parent_id           :integer(11)   
#  counter_cache       :boolean(1)    default(true)
#

class Category < Collection
	acts_as_tree 
  has_many :children, :class_name=>'Collection',:foreign_key=>'parent_id' do
		def << (category)
			return if @owner.children.include?category
			@owner.children << category
		end
	end
  has_many :memberships, :foreign_key=>:collection_id
  has_many :users, :through => :memberships, :conditions => "memberships.collection_type = 'Category'" do
	  def <<(user)
	    return if @owner.users.include?user
	    m = Membership.create(
        :user_id => user.id,
        :collection_id => @owner.id,
        :collection_type => 'Category' #@owner.class.class_name	    
	    )
	    m.save!
    end
  end
  
  has_many :linkings
  #has_many :access_contexts  
  #has_many :assets, :through => :access_contexts
  
  #has_many :groups, :through => :access_contexts, :foreign_key=>:group_id do
  has_many :groups, :through =>:linkings, :select => "DISTINCT collections.*", :foreign_key=>:group_id do
  	def <<(group)
		return if @owner.groups.include?group
	    #a = AccessContext.create(
	     a = Linking.create(
        :group_id => group.id,
        :category_id => @owner.id
	    )
	    a.save!
    end  
  end
  
  has_many :assets

  
  def bread_crumbs
    crumbs = Array.new
    for i in self.ancestors
      crumbs.insert(0, i)
    end
    crumbs
  end 
  
  # action_games_category.remove_all_groups
  def remove_all_groups
    self.groups.each do| m | 
      remove_group(m)
    end
  end
  
  # action_games_category.remove_group
  def remove_group(group)
    linking =Linking.find_by_category_id_and_group_id(self.id, group.id)
    linking.destroy if linking.valid?
  end
  
  class <<self
    def find_by_id_or_name(id)
      id.to_s.match(/^\d+$/) ? find(id) : find_by_name(id)
    end
  end

  validates_presence_of   :user_id, :name
  validates_uniqueness_of :name, :scope=>:parent_id
  
  #todo after create automatically add this category to the administrators group.
  #todo after create automatically add this category to the user group list if none is supplied || allow users to see categories where they are the owner.. even if they don't belong to a group containing that category.
  def validate
    errors.add_to_base "The category cannot specify itself as the parent" if parent_id == id and !new_record?
  end
  
end
