class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      	t.column :user_id        , :integer
		    t.column :created_on     , :datetime
		    t.column :updated_on     , :datetime
		    t.column :bio            , :text
		    t.column :address_line1  , :string
		    t.column :address_line2  , :string
		    t.column :city           , :string
		    t.column :state          , :string
		    t.column :country        , :string
		    t.column :postal_code    , :string
		    t.column :telephone      , :string
		    t.column :fax            , :string
    end
  end

  def self.down
    drop_table :profiles
  end
end
