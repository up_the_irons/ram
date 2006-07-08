class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people do |t|
	  t.column :user_id       , :integer
	  t.column :first_name    , :string  , :limit=>200 , :default=>""
	  t.column :last_name     , :string  , :limit=>200 , :default=>""
	  t.column :gender        , :integer , :default=>0 , :null=>false 
	  t.column :date_of_birth , :date
	  t.column :created_on    , :datetime
	  t.column :updated_on    , :datetime
    end
  end

  def self.down
    drop_table :people
  end
end