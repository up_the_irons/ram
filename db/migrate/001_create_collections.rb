class CreateCollections < ActiveRecord::Migration
  def self.up
	  create_table "collections", :force => true do |t|
		t.column "name"         , :string
		t.column "description"  , :text
		t.column "public"       , :boolean , :default=>true
		t.column "user_id"      , :integer
		t.column "type"         , :string
		t.column "state_id"     , :integer
	  end
	  create_table "memberships", :force => true do |t|
		t.column "user_id"         , :integer
		t.column "collection_id"   , :integer
		t.column "collection_type" , :string
		t.column "state_id"        , :integer, :default => 0
		t.column "created_at"      , :datetime
	  end
  end

  def self.down
    drop_table :collections
	drop_table :memberships
  end
end
