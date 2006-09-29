# Schema as of Thu Sep 28 14:11:12 PDT 2006 (schema version 17)
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
#  permanent           :boolean(1)    
#

class Category < Collection
	acts_as_tree 
  acts_as_taggable

  include TagMethods

  has_many :children, :class_name=>'Collection',:foreign_key=>'parent_id' do
		def << (category)
			return if @owner.children.include?category
			@owner.children << category
		end
	end
	has_many :changes, :finder_sql=>'SELECT DISTINCT * ' +
        'FROM changes c WHERE c.record_id = #{id} AND c.record_type = "Category" ORDER BY c.created_at'
  
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
  
  has_many :assets, :order=>'updated_on DESC'
  has_many :articles, :order=>'published_at DESC'

  def contents
    [articles,assets]
  end
  
  
  def bread_crumbs
    crumbs = Array.new
    for i in self.ancestors
      crumbs.insert(0, i)
    end
    crumbs
  end 
  
  
  def remove_all_groups
    self.groups.each do| m | 
      remove_group(m)
    end
  end
  

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
