# Schema as of Sat Aug 26 15:14:40 PDT 2006 (schema version 12)
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

# Schema as of Sat Jun 24 11:18:29 PDT 2006 (schema version 6)
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
  
  #has_many :assets, :through=> :linkings, :source=>:asset, :select => "DISTINCT linkings.linkable_id", :conditions=>"linkings.linkable_type='Asset'" do
	has_many :assets, :through=> :linkings, :source=>:asset, :conditions=>"linkings.linkable_type='Asset'" do
	  def <<(asset)
	    return false if @owner.assets.include?asset
	    l = Linking.create(
	      :linkable_id => asset.id,
	      :linkable_type => 'Asset',
	      :group_id => @owner.id
	    )
	    l.save!
	  end
	end
  
  def bread_crumbs
    crumbs = Array.new
    for i in self.ancestors
      crumbs.insert(0, i)
    end
    crumbs
  end 

  validates_presence_of   :user_id,:name
  validates_uniqueness_of :name, :scope=>:parent_id
  
  #todo after create automatically add this category to the administrators group.
  #todo after create automatically add this category to the user group list if none is supplied
  def validate
    errors.add_to_base "The category cannot specify itself as the parent" if parent_id == id and !new_record?
  end
  
end
