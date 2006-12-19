#--
# $Id$
#
# Copyright (c) 2006 Mark Daggett, Garry Dolley
#
# This file is part of RAM (Ruby Asset Manager) 
# 
# Released under the MIT / X11 License.  See LICENSE file for details.
#++

require 'digest/sha1'
# require File.dirname(__FILE__) + '/../../lib/overrides_finder.rb'
class User < ActiveRecord::Base
  # has_a_custom_finder
  
  has_one  :person
  has_one  :profile
  has_one  :avatar
  
  has_many :memberships
  has_many :articles
  has_many :assets do
    def <<(asset)
      return false if @owner.assets.include?(asset)
      super
    end
  end
  has_many :event_subscriptions
  
  # has_a_collection :of =>%w( feeds )
   TODO: Abstract this inside the acts_as_subscribable plug-in.... however to do this we need to find out why the user model will not load 
   the mixin associations. It may be because of the user_observer. 
   The ideal format is: acts_as_subscribable :subscribe_to=>['Feed']
   has_many :feeds, :finder_sql => 'SELECT DISTINCT f.* ' +
         'FROM feeds f, subscriptions s ' +
        'WHERE s.subscribed_to_type = \'Feed\' AND s.subscriber_id = #{id} AND s.subscriber_type = \'User\' AND f.id = s.subscribed_to_id' do
    
    # @user.feeds << Feed.find(:first)
    def <<(feed)
      return if @owner.feeds.include?(feed)
  
      Subscription.create(
        :subscribed_to_type => 'Feed',
        :subscribed_to_id => feed.id,
        :subscriber_type => 'User',
        :subscriber_id => @owner.id
      )
      
      # Reload the user's feeds to ensure the correct count
      @owner.feeds(true)
    end
    
    # @user.feeds.unsubscribe @user.feeds[0]
    def unsubscribe(feed)
      return unless @owner.feeds.include?(feed)
      s = Subscription.find_by_subscriber_id_and_subscriber_type_and_subscribed_to_type_and_subscribed_to_id(@owner.id, 'User', 'Feed', feed.id)
      return unless s
      s.destroy # Destroy the subscription.
      
      # Reload the user's feeds to ensure the correct count
      @owner.feeds(true)
    end
   end
  
  has_many :groups, :through => :memberships,
                    :conditions => "memberships.collection_type = 'Group'", :include => :categories do

    # @user.groups << Group.find(2)
    def <<(group)
      return if @owner.groups.include?(group)
      Membership.create(
        :user_id => @owner.id,
        :collection_id => group.id,
        :collection_type => 'Group'      
      )
      GroupObserver.after_add(group, @owner)
    end
  end
  
  has_many :changes, :finder_sql => 'SELECT DISTINCT * ' +
        'FROM changes c WHERE c.record_id = #{id} AND c.record_type = "User" ORDER BY c.created_at'
  
  has_many :my_groups, :class_name => 'Collection', :foreign_key => 'user_id'

  STATUS = ['Pending','Suspended','Active','Deleted'].freeze
            
  def pending_memberships(reload = true) # now with magic caching
    return [] if my_groups.size == 0
    @pending_membership_count = nil if reload
    @pending_membership_count ||= Membership.find(:all, :conditions => ['state_id = 0 and collection_id in (?) and collection_type = ?', my_groups.map(&:id), 'Group'])
  end

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login    , :email
  validates_presence_of     :password ,                   :if => :password_required?
  validates_presence_of     :password_confirmation,       :if => :password_required?
  validates_length_of       :password , :within => 5..40, :if => :password_required?
  validates_confirmation_of :password ,                   :if => :password_required?
  validates_length_of       :login    , :within => 3..40
  validates_length_of       :email    , :within => 3..100
  validates_uniqueness_of   :login    , :email

  before_save :encrypt_password
  
  def method_missing(*args)
    if self[args[0].to_sym]
      self[args[0].to_sym]
    elsif self.person.respond_to?args[0]
      self.person.send(*args)
    elsif self.profile.respond_to?args[0]
      self.profile.send(*args)
    else
      super
    end
  end
  
  def name
    login
  end
  
  def categories(reload = false)
    groups(reload).map { |g| g.categories(reload) }.flatten.uniq
  end
  
  def categories_as_tree(reload = false)
    make_branch = Proc.new do
      { :parent => nil, :children => [], :name => "", :id => nil }
    end

    category_ids = categories(reload).map { |c| c.id }
    tree = { :root => make_branch.call }
    categories.each do |t|
      sym = "b_#{t.id}".to_sym
      tree[sym] = make_branch.call if tree[sym].nil?
      tree[sym][:id] = t.id
      tree[sym][:name] = t.name
      # We use the category_id check to ensure that the tree displays children categories even if the user has no access to the parent.
      if t.parent_id.nil? || !category_ids.include?(t.parent_id)
        parent = :root
      else
        parent = "b_#{t.parent_id}".to_sym
        tree[parent] = make_branch.call if tree[parent].nil?
      end
      tree[sym][:parent] = parent 
      tree[parent][:children] << tree[sym]
    end

    tree
  end
  
  def groups=(new_groups)
    old_groups = groups - new_groups # Remove all groups which don't appear in the new_groups list
    new_groups = new_groups - groups # Remove the groups the user already belongs to.
    new_groups.each do |g|
      self.groups << g
    end
    
    # Delete all the old memberships, which are no longer needed.
    old_groups.each do |g|
      membership = Membership.find_by_collection_id_and_user_id(g.id, id)
      Membership.destroy(membership.id)
    end
  end

  def assets_search(query, order = nil)
    Asset.search(query, groups.map { |o| o.id }, order)
  end
  
  def articles_search(query,order= nil)
    Article.search(query, groups.map { |o| o.id }, order)
  end
  
  def accessible_articles
    articles = groups.map { |g| g.articles }
    articles = articles.flatten.uniq || []
    articles
  end

  # Returns categories this user belongs to, refined by 'query'
  def categories_search(query, order = nil)
    Collection.find(:all, :select => 'DISTINCT collections.*', :joins => 'INNER JOIN linkings ON collections.id = linkings.category_id',
                          :conditions => ["(linkings.group_id IN (#{groups.map { |o| o.id }.join(',')})) AND (( (collections.`type` = 'Category' ) ) AND ((collections.name like ?) OR (collections.description like ?) OR \
                                           (SELECT tags.name FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = collections.id AND taggings.taggable_type = 'Category' AND tags.name LIKE ?) IS NOT NULL))", "%#{query}%", "%#{query}%", "%#{query}%"],
                          :order => order)
  end

  def groups_search(query, order = nil)
    groups.find(:all, :conditions => ["name like ? OR description like ? OR \
                                      (SELECT tags.name FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id WHERE taggings.taggable_id = collections.id AND taggings.taggable_type = 'Group' AND tags.name LIKE ?) IS NOT NULL", "%#{query}%", "%#{query}%", "%#{query}%"], :order => order)
  end
  
  def encrypt_login
    self.class.encrypt_string(login)
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def account_active?
    return false if self[:state] == 3
    self[:state] > 1
  end
  
  # Used to force state because the profile object also uses "state" but
  # in a geographic context and we don't want it to get set through the method missing.
  def state
    return 3 if deleted_at
    self[:state]
  end

  def state=(status)
    self[:state] = status
    if status == 3
      update_attribute('deleted_at', Time.now)
    else
      update_attribute('deleted_at', nil)
    end
  end
  
  # Don't destroy the record just set the deleted_at key
  def destroy
    update_attribute(:deleted_at, Time.now)
  end
  
  def account_status
    case self[:state]
      when 1
        "Your account is suspended."
      when 0
        "Your account is pending approval from the administrator."
    end
  end
  
  def is_admin?
    (user.groups.include?(Group.find($APPLICATION_SETTINGS.admin_group_id)))? true : false 
  end
  
  # Expects the obj to respond to user_id
  def can_edit?(obj)
    return true if obj.user_id == user_id || is_admin?
    false
  end

  def after_create
    # TODO: Subscribe an observer to this event to notifiy admins that a user signed up
    profile = Profile.find_or_create_by_user_id(id)
    profile.save
    person = Person.find_or_create_by_user_id(id)
    person.save
  end

  class <<self

    alias_method :count_with_deleted, :count

    # Scoped count (non-deleted users)
    def count(*args)
      with_scope(:find => { :conditions => "deleted_at is NULL" }) { super }
    end

    def find_by_id_or_login(id)
      id.to_s.match(/^\d+$/) ? find(id) : find_by_login(id)
    end
    
    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      u = find_by_login(login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end
    
    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
    
    # Encrypts some data with the salt.
    def encrypt_string(clear_text)
      enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      enc.encrypt(RAM_SALT)
      data = enc.update(clear_text)
      Base64.encode64(data << enc.final)
    end
    
    # Getter method to decrypt password
    def decrypt_string(encrypted_string)  
      enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      enc.decrypt(RAM_SALT)
      text = enc.update(Base64.decode64(encrypted_string))
      decrypted_string = (text << enc.final)
    rescue
      nil
    end

    protected

    def validate_find_options(options)
      super(options.reject { |k, v| k == :include_deleted })
    end

    private

    # Scope find calls to exclude deleted accounts by default
    def find_every(options)
      if options.delete(:include_deleted) == true
        super(options)
      else
        with_scope(:find => { :conditions => "deleted_at is NULL" }) { super(options) }
      end
    end
  end
  
  protected

  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? or not password.blank?
  end
end
