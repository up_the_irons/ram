class AddAuthenticatedTable < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.column :login            , :string, :limit => 40
      t.column :email            , :string, :limit => 100
      t.column :crypted_password , :string, :limit => 40
      t.column :salt             , :string, :limit => 40
	    t.column :activation_code  , :string, :limit => 40
	    t.column :activated_at     , :datetime
	    t.column :state            , :integer, :default=>0
      t.column :created_at       , :datetime
      t.column :updated_at       , :datetime
      t.column :role             , :integer, :default=>0
      t.column :deleted_at       , :datetime, :default=>nil
    end
  end

  def self.down
    drop_table :users
  end
end
