class InitialSchema < ActiveRecord::Migration
  # These are just the new codes not already handled by previous migrations (not to be confused with EventTrigger.default_codes)
  @@default_codes = %w(UserDeleted UserSuspended GroupModification)
  
  def self.up
    create_table "articles", :force => true do |t|
       t.column "parent_id", :integer
       t.column "category_id", :integer
       t.column "user_id", :integer
       t.column "title", :string
       t.column "permalink", :string
       t.column "excerpt", :text
       t.column "body", :text
       t.column "excerpt_html", :text
       t.column "body_html", :text
       t.column "created_at", :datetime
       t.column "updated_at", :datetime
       t.column "published_at", :datetime
       t.column "children_count", :integer
       t.column "type", :string
       t.column "allow_comments", :boolean, :default => false
       t.column "status", :integer, :default => 0, :null => false
    end
    
    create_table "assets", :force => true do |t|
    end
    
    create_table "attachments", :force => true do |t|
      t.column "content_type", :string, :limit => 100
      t.column "filename", :string
      t.column "size", :integer
      t.column "db_file_id", :integer
      t.column "path", :string
      t.column "parent_id", :integer
      t.column "thumbnail", :string
      t.column "width", :integer
      t.column "height", :integer
      t.column "image_format", :string
      t.column "aspect_ratio", :float
      t.column "depth", :integer
      t.column "colors", :integer
      t.column "colorspace", :string
      t.column "resolution", :string
      t.column "description", :text
      t.column "user_id", :integer
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
      t.column "type", :string
      t.column "category_id", :integer
    end
    
    create_table "avatars", :force => true do |t|
      t.column "content_type", :string
      t.column "filename", :string
      t.column "size", :integer
      t.column "parent_id", :integer
      t.column "thumbnail", :string
      t.column "width", :integer
      t.column "height", :integer
      t.column "user_id", :integer
      t.column "db_file_id", :integer
    end
    
    create_table "changes", :force => true do |t|
      t.column "record_id", :integer
      t.column "record_type", :string
      t.column "event", :string
      t.column "user_id", :integer
      t.column "created_at", :datetime
    end
    
    create_table "collections", :force => true do |t|
      t.column "name", :string
      t.column "description", :text
      t.column "public", :boolean, :default => true
      t.column "user_id", :integer
      t.column "type", :string
      t.column "state_id", :integer
      t.column "parent_id", :integer
      t.column "counter_cache", :boolean, :default => true
      t.column "permanent", :boolean, :default=> false
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    
    create_table "db_files", :force => true do |t|
      t.column "data", :binary
    end
    
    create_table "event_subscriptions", :force => true do |t|
      t.column "user_id", :integer
      t.column "event_trigger_id", :integer
    end
    
    add_index "event_subscriptions", ["user_id"], :name => "user_id"
    add_index "event_subscriptions", ["event_trigger_id"], :name => "event_trigger_id"
    
    create_table "event_triggers", :force => true do |t|
      t.column "code", :string, :limit => 64
    end
    
    add_index "event_triggers", ["code"], :name => "event_triggers_code_index", :unique => true
    
    create_table "events", :force => true do |t|
      t.column "sender_id", :integer
      t.column "recipient_id", :integer
      t.column "subject", :text
      t.column "msg_body", :text
      t.column "created_at", :datetime
      t.column "read_at", :datetime
    end
    
    add_index "events", ["sender_id"], :name => "sender_id"
    add_index "events", ["recipient_id"], :name => "recipient_id"
    
    create_table "feeds", :force => true do |t|
      t.column "url", :string
      t.column "name", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "is_local", :boolean, :default => true
      t.column "local_path", :string
    end
    
    create_table "linkings", :force => true do |t|
      t.column "user_id", :integer
      t.column "category_id", :integer
      t.column "group_id", :integer
      t.column "linkable_id", :integer
      t.column "linkable_type", :string
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
    end
    
    create_table "memberships", :force => true do |t|
      t.column "user_id", :integer
      t.column "collection_id", :integer
      t.column "collection_type", :string
      t.column "state_id", :integer, :default => 0
      t.column "created_at", :datetime
    end
    
    create_table "paging", :force => true do |t|
      t.column "controller", :string, :limit => 128, :default => "", :null => false
      t.column "action", :string, :limit => 128, :default => "", :null => false
      t.column "num_per_page", :integer, :default => 10, :null => false
    end
    
    add_index "paging", ["controller", "action"], :name => "paging_controller_index", :unique => true
    
    create_table "people", :force => true do |t|
      t.column "user_id", :integer
      t.column "first_name", :string, :limit => 200, :default => ""
      t.column "last_name", :string, :limit => 200, :default => ""
      t.column "gender", :integer, :default => 0, :null => false
      t.column "date_of_birth", :date
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
    end
    
    create_table "profiles", :force => true do |t|
      t.column "user_id", :integer
      t.column "created_on", :datetime
      t.column "updated_on", :datetime
      t.column "bio", :text
      t.column "address_line1", :string
      t.column "address_line2", :string
      t.column "city", :string
      t.column "state", :string
      t.column "country", :string
      t.column "postal_code", :string
      t.column "telephone", :string
      t.column "fax", :string
      t.column "job_title", :string, :default => ""
      t.column "company", :string, :default => ""
    end
    
    create_table "subscriptions", :force => true do |t|
      t.column "subscriber_id", :integer
      t.column "subscriber_type", :string
      t.column "subscribed_to_id", :integer
      t.column "subscribed_to_type", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    
    create_table "taggings", :force => true do |t|
      t.column "taggable_id", :integer
      t.column "tag_id", :integer
      t.column "taggable_type", :string
    end
    
    create_table "tags", :force => true do |t|
      t.column "name", :string
    end
    
    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 40
      t.column "email", :string, :limit => 100
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "activation_code", :string, :limit => 40
      t.column "activated_at", :datetime
      t.column "state", :integer, :default => 0
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "role", :integer, :default => 0
      t.column "deleted_at", :datetime
      t.column "last_login_at", :datetime
    end
     
    execute "ALTER TABLE events ADD FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE"
    execute "ALTER TABLE events ADD FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE"
    execute "ALTER TABLE event_subscriptions ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
    execute "ALTER TABLE event_subscriptions ADD FOREIGN KEY (event_trigger_id) REFERENCES event_triggers(id) ON DELETE CASCADE"
     
    #Dirty hack for mysql because rails defaults to just "blob", which is too small for most images.
    execute "ALTER TABLE `db_files` MODIFY `data` MEDIUMBLOB" if adapter_name.to_s == "MySQL"
     
    # Make default associations. 
    EventTrigger.create(:code => 'UserSignup')
    @@default_codes.each do |code|
      EventTrigger.create(:code => code)
    end
    
    u = User.create(:login => 'admin', :password => 'admin', :password_confirmation => 'admin', :email => 'admin@localhost', :state => 2, :role => 1)

    # Subscribe the admin user to every event trigger
    EventTrigger.default_codes.each do |code|
      e = EventSubscription.new
      e.user = u
      e.event_trigger = EventTrigger.find_by_code(code)
      e.save!
    end

    u.person.first_name = "Administrator"
    u.save
    
    # Create the administration group.
    g = Group.create(:name => 'Administrators', 
                     :description => "Admins have access to all categories",
                     :public => 1,
                     :user_id => 1, 
                     :state_id => 1)
    g.update_attribute("permanent", true)
    Membership.create({:user_id=>u.id,:collection_id=>g.id,:collection_type=>'Group'})
  end

  def self.down
    %w(articles assets attachments avatars changes collections db_files event_subscriptions event_triggers events feeds linkings memberships paging people profiles subscriptions taggings tags users).each do | t |
      drop_table t.to_sym
    end
  end
end
