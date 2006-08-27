# Schema as of Sat Aug 26 15:14:40 PDT 2006 (schema version 12)
#
#  id                  :integer(11)   not null
#  login               :string(40)    
#  email               :string(100)   
#  crypted_password    :string(40)    
#  salt                :string(40)    
#  activation_code     :string(40)    
#  activated_at        :datetime      
#  state               :integer(11)   default(0)
#  created_at          :datetime      
#  updated_at          :datetime      
#  role                :integer(11)   default(0)
#  last_login_at       :datetime      
#

require 'digest/sha1'
class User < ActiveRecord::Base
	has_one  :person
	has_one  :profile
	has_many :memberships
  has_many :event_subscriptions
	#has_many :taggings
	
  #has_many :collections, :through => :memberships
	has_many :groups, :through=>:memberships,
	                  :conditions => "memberships.collection_type = 'Group'",:include=>:categories do

    # @user.groups << Group.find(2)
    def <<(group)
      return if @owner.groups.include?(group)
      Membership.create(
        :user_id => @owner.id,
        :collection_id => group.id,
        :collection_type => 'Group'	    
      )
    end
  end
  
  @@current = 0
  cattr_accessor :current
  
  has_many :my_groups, :class_name => 'Collection', :foreign_key => 'user_id'
  STATUS = ['Pending','Suspended','Active'].freeze
            
  def pending_memberships(reload = true) # now with magic caching
    return [] if my_groups.size == 0
    @pending_membership_count = nil if reload
    @pending_membership_count ||= Membership.find(:all, :conditions => ['state_id = 0 and collection_id in (?) and collection_type = ?', my_groups.map(&:id), 'Group'])
  end

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 5..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email
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
  
  def categories
    # todo: the list of categories don't change often so you should find some way to cache this to prevent having to query for it everytime.
    categories = []
    #for g in groups
    #  for c in g.categories
    #    categories << c
    #  end
    #end
    groups.map{|g| categories << g.categories }.flatten.uniq
    #categories = categories.flatten
    #categories = categories.uniq
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
    self[:state] > 1
  end
  
  def account_status
    case self[:state]
      when 1
        "Your Account is Suspended"
      when 0
        "Your Account is pending approval from the administrator"
    end
  end
  
  def is_admin?
    #todo as the application grows this should be broken out into its own model probably somehthing like a role model
    role == 1
  end

  def after_create
    #todo subscribe an observer to this event to notifiy admins that a user signed up
    profile = Profile.find_or_create_by_user_id(id)
    profile.save
    person = Person.find_or_create_by_user_id(id)
    person.save
    #todo create a unique token which can be unsed to identify the user for events like uploading in a sessionless state or reading a feed without supplying username and pasword
  end

  class <<self
    def find_by_id_or_login(id)
      id.to_s.match(/^\d+$/) ? find(id) : find_by_login(id)
    end
    
    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      u = find_by_login(login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end
    
    # TODO: DRY this up, the same function appears in the Group model
    
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
    
    # getter method to decrypt password
    def decrypt_string(encrypted_string)  
      enc = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
      enc.decrypt(RAM_SALT)
      text = enc.update(Base64.decode64(encrypted_string))
      decrypted_string = (text << enc.final)
    rescue
      nil
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
