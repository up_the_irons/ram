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
class Group < Collection
  acts_as_taggable
  include TagMethods

	has_many :memberships, :foreign_key=>:collection_id
	has_many :users, :through => :memberships, :conditions => "memberships.collection_type = 'Group'" do
	  def <<(user)
	    return if @owner.users.include?user
	    m = Membership.create(
        :user_id => user.id,
        :collection_id => @owner.id,
        :collection_type => 'Group' #@owner.class.class_name	    
	    )
	    m.save!
		
      # After we add a user to a group, we want the associated 'users' object to have the current list of users automatically,
      # so we must reload the users cache here. If this behavior is not desired, comment out this line.
      @owner.users(true) 

		  #TODO: add category ids to user's category tree
    end
	end
	
	has_many :linkings
	
	#TODO: Possibly make this more generic and accept many polymorphic types by using @owner.class.class_name in place of assets
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
	
	has_many :articles, :through=> :linkings, :source=>:article, :conditions=>"linkings.linkable_type='Article'" do
	  def <<(article)
	    return false if @owner.articles.include?article
	    l = Linking.create(
	      :linkable_id => article.id,
	      :linkable_type => 'Article',
	      :group_id => @owner.id
	    )
	    l.save!
	  end
	end
	
	has_many :changes, :finder_sql=>'SELECT DISTINCT * ' +
        'FROM changes c WHERE c.record_id = #{id} AND c.record_type = "Group" ORDER BY c.created_at'
	
	
	#has_many :categories, :through => :access_contexts, :foreign_key=>:category_id do
	has_many :categories, :through => :linkings, :select => "DISTINCT collections.*", :foreign_key=>:category_id do
	  def <<(category)
	    return if @owner.categories.include?category
      a = Linking.create(
        :category_id => category.id,
        :group_id => @owner.id
	    )
	    a.save!
    end
	end
	
	def members
    users
  end
  
  def permanent?
    self.permanent
  end
  
  def public?
    self.public
  end
	
	def leader
		User.find(@owner.user_id)
	end
  
  # switch_ownership(5)
  def switch_ownership(new_owner)
    old_owner = self.user_id
    user_id = new_owner
    save!
    m = Membership.create(:user_id => old_owner, :state_id => 2, :collection_id => self.id, :collection_type => 'Group')    
    memberships.find_by_user_id(new_owner).destroy rescue nil
  end
  
  # enemies.remove_all_members
  def remove_all_members
    self.members.each do| m | 
      remove_member(m)
    end
  end
  
  def remove_all_users
    remove_all_members
  end
  
  # enemeies.remove_member
  def remove_member(member)
    membership = Membership.find_by_user_id_and_collection_id(member.id, self.id)
    membership.destroy if membership     
  end

  def remove_user(user)
    remove_member(user)
  end

  validates_presence_of :user_id, :name
  validates_uniqueness_of :name
  validates_unchangeable :name, { :message => "A perminant Group's name cannot be changed." , :if=> Proc.new{|group| group.permanent} }
  
  
  #todo after save add user that created group to membership list
  
  # Returns an array of User objects that are not members of this group
  def non_members(reload = false)
    User.find(:all) - users(reload)
  end
  
  def after_create
    #FIXME this should go in an observer but I am having trouble getting it to work.
    #breakpoint
    #@users = users
    #g = Group.find_by_name(ADMIN_GROUP).users.each{|m| @users << m}
    #self.users(true)
  end

  class <<self
    def find_by_id_or_name(id)
      id.to_s.match(/^\d+$/) ? find(id) : find_by_name(id)
    end
  end
end
