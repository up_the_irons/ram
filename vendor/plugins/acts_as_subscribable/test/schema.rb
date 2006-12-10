ActiveRecord::Schema.define(:version => 0) do
  
  create_table "subscriptions", :force => true do |t|
    t.column "subscriber_id", :integer
    t.column "subscriber_type", :string
    t.column "subscribed_to_id", :integer
    t.column "subscribed_to_type", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end
  
  create_table "printings", :force => true do |t|
    t.column "title", :string
    t.column "publisher", :string
    t.column "type", :string
  end
  
  create_table "junk_mails", :force => true do |t|
    t.column "title", :string
    t.column "spammer", :string
  end
  
  create_table "letters", :force => true do |t|
    t.column "subject", :string
    t.column "body", :string
  end
  
  create_table "readers", :force => true do |t|
    t.column "name", :string
  end  
end